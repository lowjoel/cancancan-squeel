# CanCanCan-Squeel [![Build Status](https://travis-ci.org/lowjoel/cancancan-squeel.svg?branch=master)](https://travis-ci.org/lowjoel/cancancan-squeel)
[![Code Climate](https://codeclimate.com/github/lowjoel/cancancan-squeel/badges/gpa.svg)] (https://codeclimate.com/github/lowjoel/cancancan-squeel) [![Coverage Status](https://coveralls.io/repos/github/lowjoel/cancancan-squeel/badge.svg?branch=master)](https://coveralls.io/github/lowjoel/cancancan-squeel?branch=master) [![security](https://hakiri.io/github/lowjoel/cancancan-squeel/master.svg)](https://hakiri.io/github/lowjoel/cancancan-squeel/master) [![Inline docs](http://inch-ci.org/github/lowjoel/cancancan-squeel.svg?branch=master)](http://inch-ci.org/github/lowjoel/cancancan-squeel)

This is an adapter for the [CanCanCan](https://github.com/CanCanCommunity/cancancan) authorisation
library to automatically generate SQL queries from ability rules.

This differs from the default ActiveRecord implementation in that it uses
[squeel](https://github.com/activerecord-hackery/squeel) to generate SQL queries. This no longer
uses
 - `includes` (which incurs eager loading overhead)
 - `WHERE` fragments, joined lexically using `OR` or `AND` or `NOT`.

As a side effect of using `squeel`, this allows self-joins in rule definitions.

## Usage

In your `Gemfile`, insert the following line:

```ruby
gem 'cancancan-squeel'
```

after you included `cancancan`.
