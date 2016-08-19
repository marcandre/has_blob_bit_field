# HasBlobBitField

A Rails extension to treat a binary column (blob) as a sequence of `true`/`false` flags (bits)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has_blob_bit_field'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_blob_bit_field

## Example Usage

```
# Migration:
def change
	add_column :whatevers, :many_flags_blob, :binary
end

# Model:

class YourModel < ActiveRecord::Base
	has_blob_field :many_flags
end

# Usage:

o = YourModel.new
o.many_flags.size # => 0
o.many_flags.size = 666 # Can be as big as 8 times the binary limit of your column
o.many_flags[42] # => false
o.many_flags[42] = true
o.many_flags[700] # => IndexError
```

## Notes:

* The convention is that your column has the same name as your accessing method with a `'_blob'` suffix, but you can specify the column to use when calling `has_blob_field`.

* The first flag is stored using the highest bit of the first byte.

* The size is always rounded up to a multiple of 8.

* Accessing out of bounds indices raises an `IndexError`, but code could be adapted easily to return `nil` instead.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcandre/has_blob_bit_field.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

