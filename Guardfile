# A sample Guardfile
# More info at https://github.com/guard/guard#readme
#
guard 'minitest' do
  watch(%r|^spec/(.*)_spec\.rb|)
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})   { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r|^spec/minitest_helper\.rb|) { "spec" }
end
