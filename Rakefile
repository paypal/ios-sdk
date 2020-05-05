def run cmd
  File.popen(cmd) { |file|
    if block_given?
      result = ''
      result << file.gets until file.eof?
      yield result
    else
      puts file.gets until file.eof?
    end
  }
  $? == 0
end

def run! cmd
  run(cmd) or fail("Command failed with non-zero exit status #{$?}:\n$ #{cmd}")
end

def jazzy_command
  %W[jazzy
      --objc
      --author Braintree
      --author_url https://developer.paypal.com/docs/limited-release/ppcp-sdk/
      --github_url https://github.com/paypal/ios-sdk
      --sdk iphonesimulator
      --output docs_output
      --xcodebuild-arguments --objc,PayPal/Public/PayPal.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd)
      --min-acl internal
      --theme fullwidth
      --module PayPal
  ].join(' ')
end

desc "Generate documentation via jazzy and push to GH"
task :publish_docs => %w[docs:generate docs:publish docs:clean]

namespace :docs do

  desc "Generate docs with jazzy"
  task :generate do
    run! 'rm -rf docs_output'
    run(jazzy_command)
    puts "Generated HTML documentation at docs_output"
  end

  task :publish do
    run 'git branch -D gh-pages'
    run! 'git add docs_output'
    run! 'git commit -m "Publish docs to github pages"'
    puts "Generating git subtree, this will take a moment..."
    run! 'git subtree split --prefix docs_output -b gh-pages'
    run! 'git push -f origin gh-pages:gh-pages'
  end

  task :clean do
    run! 'git reset HEAD~'
    run! 'git branch -D gh-pages'
    puts "Published docs to gh-pages branch"
    run! 'rm -rf docs_output'
  end

end