require "spec_helper"

describe Mongoid::Paranoia do

  before do
    Person.delete_all
    ParanoidPost.all.each(&:delete!)
  end

  describe "#destroy!" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      before do
        post.destroy!
      end

      let(:raw) do
        ParanoidPost.collection.find_one(post.id)
      end

      it "hard deletes the document" do
        raw.should be_nil
      end

      it "executes the before destroy callbacks" do
        post.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        post.after_destroy_called.should be_true
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      before do
        phone.destroy!
      end

      let(:raw) do
        Person.collection.find_one(person.id)
      end

      it "hard deletes the document" do
        raw["paranoid_phones"].should be_empty
      end

      it "executes the before destroy callbacks" do
        phone.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        phone.after_destroy_called.should be_true
      end
    end
  end

  describe "#destroy" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      before do
        post.destroy
      end

      let(:raw) do
        ParanoidPost.collection.find_one(post.id)
      end

      it "soft deletes the document" do
        raw["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          ParanoidPost.find(post.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "executes the before destroy callbacks" do
        post.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        post.after_destroy_called.should be_true
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      before do
        phone.destroy
      end

      let(:raw) do
        Person.collection.find_one(person.id)
      end

      it "soft deletes the document" do
        raw["paranoid_phones"].first["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          person.paranoid_phones.find(phone.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "does not include the document in the relation" do
        person.paranoid_phones.scoped.should be_empty
      end

      it "executes the before destroy callbacks" do
        phone.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        phone.after_destroy_called.should be_true
      end
    end
  end

  describe "#destroyed?" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns true" do
          post.should be_destroyed
        end
      end

      context "when the document is soft deleted" do

        before do
          post.destroy
        end

        it "returns true" do
          post.should be_destroyed
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      context "when the document is hard deleted" do

        before do
          phone.destroy!
        end

        it "returns true" do
          phone.should be_destroyed
        end
      end

      context "when the document is soft deleted" do

        before do
          phone.destroy
        end

        it "returns true" do
          phone.should be_destroyed
        end
      end
    end
  end

  describe "#delete!" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      before do
        post.delete!
      end

      let(:raw) do
        ParanoidPost.collection.find_one(post.id)
      end

      it "hard deletes the document" do
        raw.should be_nil
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      before do
        phone.delete!
      end

      let(:raw) do
        Person.collection.find_one(person.id)
      end

      it "hard deletes the document" do
        raw["paranoid_phones"].should be_empty
      end
    end
  end

  describe "#delete" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      before do
        post.delete
      end

      let(:raw) do
        ParanoidPost.collection.find_one(post.id)
      end

      it "soft deletes the document" do
        raw["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          ParanoidPost.find(post.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      before do
        phone.delete
      end

      let(:raw) do
        Person.collection.find_one(person.id)
      end

      it "soft deletes the document" do
        raw["paranoid_phones"].first["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          person.paranoid_phones.find(phone.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "does not include the document in the relation" do
        person.paranoid_phones.scoped.should be_empty
      end
    end
  end

  describe "#restore" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(:title => "testing")
      end

      before do
        post.delete
        post.restore
      end

      it "removes the deleted at time" do
        post.deleted_at.should be_nil
      end

      it "persists the change" do
        post.reload.deleted_at.should be_nil
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create(:ssn => "888-88-1212")
      end

      let(:phone) do
        person.paranoid_phones.create(:number => "911")
      end

      before do
        phone.delete
        phone.restore
      end

      it "removes the deleted at time" do
        phone.deleted_at.should be_nil
      end

      it "persists the change" do
        person.reload.paranoid_phones.first.deleted_at.should be_nil
      end
    end
  end
end
