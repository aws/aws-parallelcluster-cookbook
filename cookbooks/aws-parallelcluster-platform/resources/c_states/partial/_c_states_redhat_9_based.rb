action :setup do
  return if !x86_instance? || on_docker?
  shell_out!('grubby --update-kernel=ALL --args="intel_idle.max_cstate=1 processor.max_cstate=1"')
end
