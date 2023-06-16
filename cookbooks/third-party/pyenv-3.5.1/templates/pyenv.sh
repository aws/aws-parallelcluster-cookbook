# Prefer a user pyenv over a system-wide install
if [ -s "${HOME}/.pyenv/bin" ]; then
    pyenv_root="${HOME}/.pyenv"
    pyenv_init="pyenv init -"
elif [ -s "<%= @global_prefix %>" ]; then
    pyenv_root="<%= @global_prefix %>"
    export PYENV_ROOT=${pyenv_root}
    # Rehashing will fail in a system install
    pyenv_init="pyenv init - --no-rehash"
fi

if [ -n "$pyenv_root" ]; then
    export PATH="${pyenv_root}/bin:$PATH"
    eval "$($pyenv_init)"
fi
