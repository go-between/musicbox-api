require 'rails_helper'

RSpec.describe Arel::FullTextSearch do
  let(:connection) { ActiveRecord::Base.connection }
  let(:table) { Arel::Table.new(:songs) }

  describe 'full text search methods' do
    include Arel::FullTextSearch

    it 'generates ts_vector SQL' do
      node = ts_vector(table[:name], table[:description])
      sql = node.to_sql

      expect(sql).to match(/to_tsvector\('english', .*name.* \|\| ' ' \|\| .*description.*\)/)
    end

    it 'generates ts_query SQL' do
      node = ts_query('search terms')
      sql = node.to_sql

      expect(sql).to eq("to_tsquery('english', 'search terms')")
    end

    it 'generates web_ts_query SQL' do
      node = web_ts_query('search terms')
      sql = node.to_sql

      expect(sql).to eq("websearch_to_tsquery('english', 'search terms')")
    end

    it 'generates plain_ts_query SQL' do
      node = plain_ts_query('search terms')
      sql = node.to_sql

      expect(sql).to eq("plainto_tsquery('english', 'search terms')")
    end

    it 'generates phrase_ts_query SQL' do
      node = phrase_ts_query('search terms')
      sql = node.to_sql

      expect(sql).to eq("phraseto_tsquery('english', 'search terms')")
    end

    it 'generates ts_headline SQL' do
      query = ts_query('search')
      node = ts_headline(table[:description], query, options: { max_words: 50 })
      sql = node.to_sql

      expect(sql).to match(/ts_headline\('english', .*description.*, to_tsquery\('english', 'search'\), 'MaxWords=50'\)/)
    end

    it 'generates ts_rank SQL' do
      vector = ts_vector(table[:name])
      query = plain_ts_query('music')
      node = ts_rank(vector, query)
      sql = node.to_sql

      expect(sql).to match(/ts_rank\(to_tsvector\('english', .*name.*\), plainto_tsquery\('english', 'music'\)\)/)
    end
  end
end
