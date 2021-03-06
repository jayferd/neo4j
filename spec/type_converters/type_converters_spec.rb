require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::TypeConverters, :type => :transactional do
  context "my own converter that respond to #to_java and #to_ruby in the Neo4j::TypeConverters module" do
    before(:all) do
      Neo4j::TypeConverters.converters = nil  # reset the list of converters since we have already started neo4j 

      module Neo4j::TypeConverters
        class MyConverter
          class << self

            def convert?(type)
              type == Object
            end

            def to_java(val)
              "silly:#{val}"
            end

            def to_ruby(val)
              val.sub(/silly:/, '')
            end
          end
        end
      end

      @clazz = create_node_mixin do
        property :thing, :type => Object

        def to_s
          "Thing #{thing}"
        end
      end
    end

    it "should convert when node initialized with a hash of properties" do
      a = @clazz.new :thing => 'hi'
      a.get_property('thing').should == 'silly:hi'
    end

    it "should convert back to ruby" do
      a = @clazz.new :thing => 'hi'
      a.thing.should == 'hi'
    end

    it "should convert when accessor method is called" do
      a       = @clazz.new
      a.thing = 'hi'
      a.get_property('thing').should == 'silly:hi'
    end

    it "should NOT convert when 'raw' set_property(key,value) method is called" do
      a = @clazz.new
      a.set_property('thing', 'hi')
      a.get_property('thing').should == 'hi'
    end

  end

  context Neo4j::TypeConverters::DateConverter, "property :born => Date" do
    before(:all) do
      @clazz = create_node_mixin do
        property :born, :type => Date
        index :born
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :born => Date.today
      val = v._java_node.get_property('born')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      now = Date.today
      v = @clazz.new :born => now
      v.born.should == now
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      yesterday = Date.today - 1
      v = @clazz.new :born => yesterday
      new_tx
      found = [*@clazz.find(:born).between(Date.today-2, Date.today)]
      found.size.should == 1
      found.should include(v)
    end
  end


  context Neo4j::TypeConverters::DateTimeConverter, "property :since => DateTime" do
    before(:all) do
      @clazz = create_node_mixin do
        property :since, :type => DateTime
        index :since
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :since => DateTime.new(1842, 4, 2, 15, 34, 0)
      val = v._java_node.get_property('since')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      since = DateTime.new(1842, 4, 2, 15, 34, 0)
      v = @clazz.new :since => since
      v.since.should == since
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      a = DateTime.new(1992, 1, 2, 15, 20, 0)
      since = DateTime.new(1992, 4, 2, 15, 34, 0)
      b = DateTime.new(1992, 10, 2, 15, 55, 0)
      v = @clazz.new :since => since
      new_tx
      found = [*@clazz.find(:since).between(a, b)]
      found.size.should == 1
      found.should include(v)
    end
  end


end
