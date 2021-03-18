# Sidekiq::Group
Addon for Sidekiq that provides similar functionality to Pro version Batches feature. Allows to group jobs into a set and follow their progress

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-group'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-group

## Usage

```ruby
class ImportBatchWorker
  include Sidekiq::Worker
  include Sidekiq::Group

  def on_complete(options)
    Import.find(options['import_id']).done!
  end

  def perform(import_id)
    import = Report.find(import_id)

    sidekiq_group(import_id: import.id) do |group|
      import.rows.each do |import_row|
        group.add(ImportWorker.perform_async(import_row.id))
      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sidekiq-group.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
