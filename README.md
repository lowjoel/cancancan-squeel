# CanCanCan-Squeel
This is an adapter for the [CanCanCan](https://github.com/CanCanCommunity/cancancan) authorisation
library to automatically generate SQL queries from ability rules.

This differs from the default ActiveRecord implementation in that it uses
[squeel](https://github.com/activerecord-hackery/squeel) to generate SQL queries. This no longer
uses
 - `includes` (which incurs eager loading overhead)
 - `WHERE` fragments, joined lexically using `OR` or `AND` or `NOT`.

As a side effect of using `squeel`, this allows self-joins in rule definitions.
