# Telephone ☎️

![](https://github.com/bharget/telephone/actions/workflows/ci.yml/badge.svg)

Telephone is a light weight utility that helps you create and call service objects from anywhere within your application.

Telepone comes with a simple interface that helps with:

* Keeping your code DRY
* Encapsulating complex logic in a more readable way
* Making your code easier to test
* Gracefully handling errors and validations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'telephone'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install telephone

## Usage

`Telephone::Service` is a simple utility class for creating and calling service objects. It allows you to define arguments and validations, and provides
a simple interface for calling the service and determining its success.

To start, define an `ApplicationService` and inherit from `Telephone::Service`.

```ruby
# /app/services/application_service.rb

class ApplicationService < Telephone::Service
end
```

A very simple example of a service object:

```ruby
class SimpleExample < ApplicationService
  def call
    "Hello World"
  end
end

s = SimpleExample.call #=> <#SimpleExample @result="Hello World">
s.success? #=> true
s.result #=> "Hello World"
```

### Arguments

You can define arguments for the service object. These arguments will be passed to the service object's `call` method, and will be available as an attribute.

```ruby
class SimpleExample < ApplicationService
  argument :name

  def call
    "Hello, #{name}."
  end
end

SimpleExample.call(name: "Benjamin").result #=> "Hello, Benjamin."
```

Arguments can also be required, which will raise an `ArgumentError` if not provided:

```ruby
class SimpleExample < ApplicationService
  argument :name, required: true

  def call
    "Hello, #{name}."
  end
end

SimpleExample.call #=> ArgumentError: missing required argument: name
SimpleExample.call(name: nil) #=> works - nil is a valid value
```

You can also give a default value for an argument.

```ruby
argument :name, default: "Benjamin"
```

Defaults can also be callable (procs or lambdas) that are evaluated at runtime. Callable defaults have access to other attributes and are processed in definition order:

```ruby
class GreetingService < ApplicationService
  argument :first_name, default: "John"
  argument :last_name, default: "Doe"
  argument :full_name, default: -> { "#{first_name} #{last_name}" }
  argument :created_at, default: -> { Time.current }

  def call
    "Hello, #{full_name}!"
  end
end

GreetingService.call.result #=> "Hello, John Doe!"
GreetingService.call(first_name: "Jane").result #=> "Hello, Jane Doe!"
```

Arguments can also have inline validations using the `validates:` option:

```ruby
argument :email, validates: { format: { with: /@/ } }
argument :name, required: true, validates: { length: { minimum: 2 } }
```

### Validations

Since `Telephone::Service` includes `ActiveModel::Model`, you can define validations in the same way you would for an ActiveRecord model.

```ruby
validates :name, format: { with: /\A[a-zA-Z]+\z/ }
validate :admin_user?

def admin_user?
  errors.add(:user, "not admin") unless user.admin?
end
```

If a validation fails, the service object will not execute and return `nil` as the result of th call. You can check the status of the service object by calling `success?`.

```ruby
s = SomeService.call
s.success? #=> false
```

## Best Practices

Service objects are a great way to keep your code DRY and encapsulate business logic. As a rule of thumb, try to keep your service objects to a single responsibility. If you find yourself dealing with very complex logic, consider breaking it up into smaller services.

## Development

After checking out the repo, run `bin/setup` to install dependencies. This will install the dependencies for each subgem and run the entire test suite.

To experiment, you can run `bin/console` for an interactive prompt.

### Documentation

This project is documented using YARD. All code should be well documented via the YARD syntax prior to merging.

You can access the docmentation by starting up the YARD server.

```sh
yard server --reload
```

The `--reload`, or `-r`, flag tells the server to auto reload the documentation on each request.

Once the server is running, the documentation will by available at http://localhost:8808

## Upgrading to 2.0

Version 2.0 changes the behavior of `required: true`. Previously it added a presence validation; now it raises `ArgumentError` if the argument key isn't provided.

To migrate, run:

```bash
rake telephone:migrate                    # defaults to app/services
rake telephone:migrate[path/to/services]  # custom path
```

This adds `validates: { presence: true }` to preserve the old validation behavior.
