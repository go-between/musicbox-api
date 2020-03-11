FROM ruby:2.6.5
RUN apt-get update -qq && apt-get upgrade -qqy
RUN apt-get -qqy install cmake
RUN gem install bundler -v 2.0.2
RUN gem update --system

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD .ruby-version $APP_HOME/
ADD Gemfile* $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile BUNDLE_JOBS=4 BUNDLE_WITHOUT=production:staging

RUN bundle install

RUN passenger-config install-standalone-runtime --auto
RUN passenger-config build-native-support

COPY . $APP_HOME

CMD ["echo", "Commands: `bin/passenger start -p $PORT`]
