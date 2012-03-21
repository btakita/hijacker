require "spec_helper"

module Hijacker
  describe Database do
    let(:host) { Hijacker::Host.create!(:hostname => "localhost") }
    let(:alias_db) { Hijacker::Alias.new(:name => "alias_db") }

    it "has many aliases" do
      subject.aliases << alias_db
      subject.aliases.should == [alias_db]
    end

    it "belongs to a host" do
      subject.host = host
      subject.host.should == host
    end

    it "requires a host" do
      subject.host = nil
      subject.should_not be_valid
      subject.errors.on(:host_id).should == "can't be blank"

      subject.host = host
      subject.should be_valid
    end

    describe "#connect_each" do
      def db(name)
        mock("#{name}_db", :database => name)
      end

      before (:each) do
        Database.stub!(:all).and_return([ db("one"), db("two"), db("three") ])
        Hijacker.stub!(:connect)
      end

      it "Calls the block once for each database" do
        count = 0
        Database.connect_each do |db|
          count += 1
        end
        count.should == Database.all.size
      end

      it "Passes the name of the database to the block" do
        db_names = []
        Database.connect_each do |db|
          db_names << db
        end
        db_names.should == Database.all.map(&:database)
      end

      it "connects to each of the database and reconnects to the original" do
        original_db = Hijacker::Database.current
        Hijacker.should_receive(:connect).exactly(Database.all.size + 1).times
        Database.connect_each do |db|
          # noop
        end

        Hijacker::Database.current.should == original_db
      end
    end
  end
end
