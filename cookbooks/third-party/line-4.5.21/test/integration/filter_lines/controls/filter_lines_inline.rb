#
# Spec tests for the inline filters
#

control 'filter_lines_inlune' do
  describe file('/tmp/inline_nothing') do
    it { should exist }
    its('content') do
      should cmp <<~EOF
      sator
      arepo
      tenet
      opera
      rotas
    EOF
    end
  end
  describe file_ext('/tmp/inline_nothing') do
    it { should have_correct_eol }
    its('size_lines') { should eq 5 }
  end

  describe file('/tmp/inline_reverse') do
    it { should exist }
    its('content') do
      should cmp <<~EOF
      rotas
      opera
      tenet
      arepo
      sator
    EOF
    end
  end
  describe file_ext('/tmp/inline_reverse') do
    it { should have_correct_eol }
    its('size_lines') { should eq 5 }
  end
end
