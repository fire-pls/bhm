FOO_TEAM = {
  name: "Foos",
  rank: 1,
  users: [
    {
      name: "Mario Lopez",
      email: "lil@mr.e",
      tos_acceptance: true,
      address: {
        street: "foosgonewild"
      },
      profile: {
        introduction: "foosgonewild.com/shop",
        hobbies: ["stuntin'"]
      },
      meta: {
        created_at: DateTime.parse("2019-09-01"),
        updated_at: DateTime.parse("2019-09-01"),
        uuid: "f0000000-f000-f000-f000-f00000000000"
      }
    }
  ],
  budget: {
    amount: 1_000_000,
    meta: {
      created_at: DateTime.parse("2019-09-01"),
      updated_at: DateTime.parse("2019-09-01"),
      uuid: "f0000000-f000-f000-f000-f00000000000"
    }
  },
  meta: {
    created_at: DateTime.parse("2019-09-01"),
    updated_at: DateTime.parse("2019-09-01"),
    uuid: "f0000000-f000-f000-f000-f00000000000"
  }
}.freeze

RSpec.describe Bhm do
  it "has a version number" do
    expect(Bhm::VERSION).not_to be nil
  end
end

RSpec.describe "examples" do
  let(:extended_hash) { hash.extend(described_class) }

  describe User do
    context "with a valid hash" do
      let(:hash) { FOO_TEAM[:users].first.dup }
      it "#valid?" do
        expect(extended_hash.valid?).to be(true)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to_not raise_error
      end
    end

    context "with invalid hash" do
      let(:hash) { {foo: "bar"} }

      it "#valid?" do
        expect(extended_hash.valid?).to be(false)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to raise_error(Bhm::Errors::InvalidHash)
      end
    end
  end

  describe Meta do
    context "with a valid hash" do
      let(:hash) { FOO_TEAM[:meta].dup }
      it "#valid?" do
        expect(extended_hash.valid?).to be(true)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to_not raise_error
      end
    end

    context "with invalid hash" do
      let(:hash) { {foo: "bar"} }

      it "#valid?" do
        expect(extended_hash.valid?).to be(false)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to raise_error(Bhm::Errors::InvalidHash)
      end
    end
  end

  describe Team do
    context "with a valid hash" do
      let(:hash) { FOO_TEAM.dup }
      it "#valid?" do
        expect(extended_hash.valid?).to be(true)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to_not raise_error
      end
    end

    context "with invalid hash" do
      let(:hash) { {foo: "bar"} }

      it "#valid?" do
        expect(extended_hash.valid?).to be(false)
      end

      it "#validate!" do
        expect { extended_hash.validate! }.to raise_error(Bhm::Errors::InvalidHash)
      end
    end
  end
end
