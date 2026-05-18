#!/usr/bin/env bash
# Render用のビルドスクリプト
# Render Dashboard の Build Command にこのスクリプトを設定する

# いずれかのコマンドが失敗したらビルド全体を停止する
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:prepare
