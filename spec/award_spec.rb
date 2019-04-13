RSpec.describe Award do
  describe "::fetch_top_contributors" do
    let(:repo_path) { 'github.com/some/repo' }

    subject { Award.fetch_top_contributors(repo_path) }

    it { is_expected.to be_success }

    it 'returns contributors' do
      expect(subject.value!).to eq ['one', 'two', 'three']
    end

    context 'with invalid path' do
      let(:repo_path) { 'invalid_path' }
    end
  end
end
