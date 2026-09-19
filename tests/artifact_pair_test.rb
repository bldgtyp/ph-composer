# frozen_string_literal: true

require_relative "test_helper"

# The HBJSON and its report are written as one pair or not at all, only into test-owned temporary
# folders (CONTRACTS.md C6). Every injected failure leaves the previous pair, and any unrelated file
# beside it, byte for byte as it was.
class ArtifactPairTest < PhComposerTestCase
  Pair = PhComposer::Export::ArtifactPair
  Crash = Class.new(Exception)

  def test_writes_and_replaces_one_coordinated_pair
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      report = Pair.report_path(hbjson)
      first = Pair::Transaction.new(hbjson, :run_id => "one").commit(model("one"), report_html("one"))
      refute first.replaced
      second = Pair::Transaction.new(hbjson, :run_id => "two").commit(model("two"), report_html("two"))

      assert second.replaced
      assert_equal model("two"), File.read(hbjson)
      assert_equal report_html("two"), File.read(report)
      assert_empty owned_files(directory)
    end
  end

  def test_the_pair_gets_the_users_ordinary_file_permissions
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      Pair::Transaction.new(hbjson, :run_id => "one").commit(model("one"), report_html("one"))

      expected = 0o666 & ~File.umask
      assert_equal expected, File.stat(hbjson).mode & 0o777
      assert_equal expected, File.stat(Pair.report_path(hbjson)).mode & 0o777
    end
  end

  def test_refuses_an_incomplete_prior_pair
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      File.write(hbjson, model("old"))

      assert_raises(Pair::IncompletePriorPairError) do
        Pair::Transaction.new(hbjson, :run_id => "new").commit(model("new"), report_html("new"))
      end
      assert_equal model("old"), File.read(hbjson)
      refute File.exist?(Pair.report_path(hbjson))
    end
  end

  def test_a_failed_rename_restores_the_prior_pair_and_leaves_other_files_alone
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      report = Pair.report_path(hbjson)
      File.write(hbjson, model("old"))
      File.write(report, report_html("old"))
      File.write(File.join(directory, "notes.txt"), "unrelated")
      before = snapshot(directory)
      rename = File.method(:rename)
      failing = lambda do |from, to|
        raise Errno::EACCES, to if to == report && from.include?(".stage")

        rename.call(from, to)
      end

      File.stub(:rename, failing) do
        assert_raises(Pair::PairError) do
          Pair::Transaction.new(hbjson, :run_id => "new").commit(model("new"), report_html("new"))
        end
      end
      assert_equal before, snapshot(directory)
    end
  end

  def test_every_recoverable_commit_failure_restores_the_prior_pair
    points = %i[
      after_hbjson_stage after_report_stage after_journal after_hbjson_backup after_report_backup
      after_hbjson_commit after_report_commit
    ]
    points.each do |point|
      Dir.mktmpdir("phc-export-pair") do |directory|
        hbjson = File.join(directory, "model.hbjson")
        report = Pair.report_path(hbjson)
        File.write(hbjson, model("old"))
        File.write(report, report_html("old"))
        fault = proc { |current| raise IOError, current.to_s if current == point }

        assert_raises(Pair::PairError, point) do
          Pair::Transaction.new(hbjson, :run_id => "new", :fault => fault).commit(
            model("new"), report_html("new")
          )
        end
        assert_equal model("old"), File.read(hbjson), point
        assert_equal report_html("old"), File.read(report), point
        assert_empty owned_files(directory), point
      end
    end
  end

  def test_next_run_recovers_an_interrupted_commit_before_working
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      report = Pair.report_path(hbjson)
      File.write(hbjson, model("old"))
      File.write(report, report_html("old"))
      fault = proc { |point| raise Crash, "simulated process loss" if point == :after_hbjson_commit }

      assert_raises(Crash) do
        Pair::Transaction.new(hbjson, :run_id => "crash", :fault => fault).commit(
          model("new"), report_html("crash")
        )
      end

      Pair::Transaction.new(hbjson, :run_id => "recovery").recover
      assert_equal model("old"), File.read(hbjson)
      assert_equal report_html("old"), File.read(report)
      assert_empty owned_files(directory)
    end
  end

  # Process loss between staging the committed journal and renaming it leaves the prepared journal and
  # the new stage file. The next run rolls back from the journal and must also clear that stage.
  def test_next_commit_recovers_a_process_lost_while_marking_the_journal_committed
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      report = Pair.report_path(hbjson)
      File.write(hbjson, model("old"))
      File.write(report, report_html("old"))
      fault = proc { |point| raise Crash, "simulated process loss" if point == :after_committed_journal_stage }

      assert_raises(Crash) do
        Pair::Transaction.new(hbjson, :run_id => "crash", :fault => fault).commit(model("new"), report_html("crash"))
      end
      Pair::Transaction.new(hbjson, :run_id => "next").commit(model("next"), report_html("next"))

      assert_equal model("next"), File.read(hbjson)
      assert_equal report_html("next"), File.read(report)
      assert_empty owned_files(directory)
    end
  end

  def test_cleanup_interruption_keeps_the_verified_new_pair
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      report = Pair.report_path(hbjson)
      File.write(hbjson, model("old"))
      File.write(report, report_html("old"))
      fault = proc do |point|
        raise Crash, "simulated cleanup interruption" if point == :after_hbjson_backup_cleanup
      end

      assert_raises(Crash) do
        Pair::Transaction.new(hbjson, :run_id => "new", :fault => fault).commit(
          model("new"), report_html("new")
        )
      end

      assert_equal model("new"), File.read(hbjson)
      assert_equal report_html("new"), File.read(report)
      Pair::Transaction.new(hbjson, :run_id => "recovery").recover
      assert_equal model("new"), File.read(hbjson)
      assert_equal report_html("new"), File.read(report)
      assert_empty owned_files(directory)
    end
  end

  def test_failed_new_destination_leaves_no_partial_final
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      fault = proc { |point| raise IOError, "stop" if point == :after_hbjson_commit }

      assert_raises(Pair::PairError) do
        Pair::Transaction.new(hbjson, :run_id => "new", :fault => fault).commit(
          model("new"), report_html("new")
        )
      end
      refute File.exist?(hbjson)
      refute File.exist?(Pair.report_path(hbjson))
      assert_empty owned_files(directory)
    end
  end

  def test_next_run_removes_an_interrupted_journal_stage_before_any_artifact_write
    Dir.mktmpdir("phc-export-pair") do |directory|
      hbjson = File.join(directory, "model.hbjson")
      journal_stage = File.join(directory, ".model.hbjson.ph-composer-export-commit.json.stage")
      File.write(journal_stage, "partial journal")

      Pair::Transaction.new(hbjson, :run_id => "recovery").recover

      refute File.exist?(journal_stage)
      refute File.exist?(hbjson)
      refute File.exist?(Pair.report_path(hbjson))
    end
  end

  private

  def model(run_id)
    JSON.generate("type" => "Model", "run_id" => run_id)
  end

  def report_html(run_id)
    "<html><script id=\"phc-export-result\">#{run_id}</script></html>"
  end

  def snapshot(directory)
    Dir.children(directory).sort.to_h { |name| [name, File.binread(File.join(directory, name))] }
  end

  def owned_files(directory)
    Dir.children(directory).grep(/ph-composer-export/)
  end
end
