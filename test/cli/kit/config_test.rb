require 'test_helper'
require 'tmpdir'
require 'fileutils'

module CLI
  module Kit
    class ConfigTest < MiniTest::Test
      def setup
        super

        CLI::Kit.tool_name ||= 'tool'

        @tmpdir = Dir.mktmpdir
        @prev_xdg = ENV['XDG_CONFIG_HOME']
        ENV['XDG_CONFIG_HOME'] = @tmpdir
        @file = File.join(@tmpdir, 'tool', 'config')

        @config = Config.new
      end

      def teardown
        FileUtils.rm_rf(@tmpdir)
        ENV['XDG_CONFIG_HOME'] = @prev_xdg
        super
      end

      def test_config_get_returns_false_for_not_existant_key
        refute @config.get('invalid-key-no-existing')
      end

      def test_config_key_never_padded_with_whitespace
        # There was a bug that occured when a key was reset
        # We split on `=` and 'key ' became the new key (with a space)
        # This is a regression test to make sure that doesnt happen
        @config.set('key', 'value')
        assert_equal({ "[global]" => { "key" => "value" } }, @config.send(:all_configs))
        3.times { @config.set('key', 'value') }
        assert_equal({ "[global]" => { "key" => "value" } }, @config.send(:all_configs))
      end

      def test_config_set
        @config.set('some-key', '~/.test')
        assert_equal("[global]\nsome-key = ~/.test", File.read(@file))

        @config.set('some-key', nil)
        assert_equal '', File.read(@file)

        @config.set('some-key', '~/.test')
        @config.set('some-other-key', '~/.test')
        assert_equal("[global]\nsome-key = ~/.test\nsome-other-key = ~/.test", File.read(@file))

        assert_equal('~/.test', @config.get('some-key'))
        assert_equal("#{ENV['HOME']}/.test", @config.get_path('some-key'))
      end

      def test_config_mutli_argument_get
        @config.set('some-parent.some-key', 'some-value')
        assert_equal 'some-value', @config.get('some-parent', 'some-key')
      end

      def test_get_section
        @config.set('some-key', 'should not show')
        @config.set('srcpath.other', 'test')
        @config.set('srcpath.default', 'Shopify')
        assert_equal({ 'other' => 'test', 'default' => 'Shopify' }, @config.get_section('srcpath'))
      end
    end
  end
end