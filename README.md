# PantryDaemonCommon

Common daemons stuff.

## Installation

Add this line to your application's Gemfile:

    gem 'pantry_daemon_common', git: 'git@github.com:wongatech/pantry_daemon_common.git'

or add artifactory to your gem sources and use it as usual gem.

And then execute:

    $ bundle

## Usage

require 'wonga/daemon/publisher' to use simple publisher.

## Contributing

1. Clone the repository from [Gerrit](https://github.com/wongatech/pantry_daemon_common)
2. Create a named feature branch with JIRA ticket (like `TD-1234_Adds_Feature_X`)
3. Write your change
4. Write [rspec](https://www.relishapp.com/rspec/rspec-core) tests for your change
5. Run `rake` ensuring they all pass
6. Write [a meaningful git commit message](https://xkcd.com/1296/) including the JIRA ticket ID and a synopsis of changes if needed
7. Run `git rebase -i`, squash your commits, retain the original Change-ID and re-run tests if you've been lone-wolfing too long
8. Run `git review` to submit a Change Request ID and link it to JIRA
