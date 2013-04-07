require 'spec_helper'

module Skylight
  describe Normalize, "sql.active_record" do
    include_context "normalizer"

    it "skips SCHEMA queries" do
      normalize(name: "SCHEMA").should == :skip
    end

    it "Processes cached queries" do
      name, title, desc, annotations =
        normalize(name: "CACHE", sql: "select * from query", binds: [])

      name.should == "db.sql.cache"
      title.should == "Cached Load"
      desc.should == nil

      annotations.should == {
        sql: "select * from query",
        binds: []
      }
    end

    it "Processes uncached queries" do
      name, title, desc, annotations =
        normalize(name: "Foo Load", sql: "select * from foo", binds: [])

      name.should == "db.sql.query"
      title.should == "Foo Load"
      desc.should == nil

      annotations.should == {
        sql: "select * from foo",
        binds: []
      }
    end

    it "Pulls out binds" do
      name, title, desc, annotations =
        normalize(name: "Foo Load", sql: "select * from foo where id = ?", binds: [[Object.new, 1]])

      name.should == "db.sql.query"
      title.should == "Foo Load"
      desc.should == nil

      annotations.should == {
        sql: "select * from foo where id = ?",
        binds: [1]
      }
    end
  end
end