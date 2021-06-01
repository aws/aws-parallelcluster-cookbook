shared_examples 'issues::gh46' do
  context 'Issue #46' do
    context 'Uniform anonuid/anongid on unrelated shares' do
      describe command("egrep -c '/tmp/share[0-9] 127.0.0.1\\(ro,sync,root_squash,anonuid=[0-9]+,anongid=[0-9]+\\)' /etc/exports") do
        its(:stdout) { should match(/3\n/) }
      end
    end

    context 'Unrelated shares are not stairstepping anonuid/anongid' do
      describe command("egrep -v '/tmp/share[0-9] 127.0.0.1\\(rw,sync,root_squash,(anonuid=[0-9]+,anongid=[0-9]+){2,}\\)' /etc/exports") do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should_not match(%r{^\/tmp\/share2[.]*anonuid=1001}) }
        its(:stdout) { should_not match(%r{^\/tmp\/share2[.]*anongid=1001}) }
        its(:stdout) { should_not match(%r{^\/tmp\/share3[.]*anonuid=1002}) }
        its(:stdout) { should_not match(%r{^\/tmp\/share3[.]*anongid=1002}) }
      end
    end
  end
end
