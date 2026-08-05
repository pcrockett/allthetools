if status is-interactive
    # Commands to run in interactive sessions can go here
    direnv hook fish | source
    starship init fish | source
    mise activate fish | source
end
