# Good Night App

Prerequisites
Make sure you have the following installed on your machine:

* Ruby (3.3.0)
* Rails (7.1.5.1)
* PostgreSQL (14.15)

Installation

Clone the repository:
```shell
git clone https://github.com/your-username/your-project.git
```

Navigate to the project directory:
```shell
cd your-project
```

Install dependencies:
```shell
bundle install
```

Copy Env file from application.yml.example
```shell
cp config/application.yml.example config/application.yml
```

Set up the database:
```shell
rails db:drop:all db:create db:migrate
```

Run Spec:
```shell
rspec
```

Run Server:
```shell
rails server
```
