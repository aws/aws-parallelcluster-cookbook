# Prefer a user pyenv over a system wide install
if [ -s "${HOME}/.pyenv/bin" ]; then
    pyenv_root="${HOME}/.pyenv"
elif [ -s "<%= @global_prefix %>" ]; then
    pyenv_root="<%= @global_prefix %>"
    export PYENV_ROOT=${pyenv_root}
fi

if [ -n "$pyenv_root" ]; then
    export PATH="${pyenv_root}/bin:$PATH"
    eval "$(pyenv init -)"
fi
