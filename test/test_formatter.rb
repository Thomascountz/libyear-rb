# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/formatters/formatter"
require "tmpdir"

class TestFormatter < Minitest::Test
  def test_raises_when_formatter_gem_is_not_installed
    error = assert_raises(ArgumentError) { LibyearRb::Formatter["nonexistent"] }

    assert_equal "Formatter gem libyear-rb-nonexistent-formatter could not be loaded.", error.message
  end

  def test_raises_when_formatter_gem_loads_but_does_not_define_expected_class
    with_fake_gem("empty", "# defines nothing\n") do
      error = assert_raises(ArgumentError) { LibyearRb::Formatter["empty"] }

      assert_equal "Formatter gem libyear-rb-empty-formatter does not define LibyearRb::EmptyFormatter.", error.message
    end
  end

  def test_returns_formatter_class_when_gem_loads_successfully
    with_fake_gem("fake", <<~RUBY) do
      module LibyearRb
        class FakeFormatter < Formatter; end
      end
    RUBY

      assert_equal "LibyearRb::FakeFormatter", LibyearRb::Formatter["fake"].name
    ensure
      LibyearRb.send(:remove_const, :FakeFormatter) if LibyearRb.const_defined?(:FakeFormatter, false)
    end
  end

  def test_name_is_case_insensitive
    with_fake_gem("fake", <<~RUBY) do
      module LibyearRb
        class FakeFormatter < Formatter; end
      end
    RUBY

      assert_equal "LibyearRb::FakeFormatter", LibyearRb::Formatter["fake"].name
      assert_equal "LibyearRb::FakeFormatter", LibyearRb::Formatter["Fake"].name
      assert_equal "LibyearRb::FakeFormatter", LibyearRb::Formatter["FAKE"].name
    ensure
      LibyearRb.send(:remove_const, :FakeFormatter)
    end
  end

  def test_raises_when_name_contains_non_letters
    error = assert_raises(ArgumentError) { LibyearRb::Formatter["foo-bar"] }
    assert_equal "Formatter name must contain only letters.", error.message

    error = assert_raises(ArgumentError) { LibyearRb::Formatter["foo_bar"] }
    assert_equal "Formatter name must contain only letters.", error.message

    error = assert_raises(ArgumentError) { LibyearRb::Formatter["foo123"] }
    assert_equal "Formatter name must contain only letters.", error.message
  end

  private

  def with_fake_gem(name, content)
    Dir.mktmpdir do |dir|
      formatter_path = Pathname.new(dir).join("libyear_rb", "formatters", "#{name}_formatter.rb")
      formatter_path.dirname.mkpath
      formatter_path.write(content)
      $LOAD_PATH.unshift(dir)
      begin
        yield
      ensure
        $LOAD_PATH.delete(dir)
      end
    end
  end
end
