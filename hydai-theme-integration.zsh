#!/usr/bin/env zsh
# Integration for hydai.zsh-theme
# This file adds ccusage support to the hydai theme

# CCUsage prompt segment for hydai theme
prompt_ccusage() {
  # Check if ccusage plugin is loaded
  if [[ "$CCUSAGE_LOADED" == "true" ]] && (( $+functions[ccusage_display] )); then
    local ccusage_info=$(ccusage_display)
    if [[ -n "$ccusage_info" ]]; then
      # Use the theme's segment function
      # You can customize the colors here
      $1_prompt_segment $0 "237" "white" "$ccusage_info"
    fi
  fi
}

# Alternative: Simpler integration without segment styling
prompt_ccusage_simple() {
  if [[ "$CCUSAGE_LOADED" == "true" ]] && (( $+functions[ccusage_display] )); then
    local ccusage_info=$(ccusage_display)
    if [[ -n "$ccusage_info" ]]; then
      echo -n "$ccusage_info"
    fi
  fi
}

# Enhanced precmd that includes ccusage updates
hydai_precmd_with_ccusage() {
  # Call original vcs_info
  vcs_info
  
  # Add a static hook to examine staged/unstaged changes
  vcs_info_hookadd set-message vcs-detect-changes
  
  # Call ccusage precmd if available
  if (( $+functions[ccusage_precmd] )); then
    ccusage_precmd
  fi
}

# Integration instructions
cat << 'EOF'
=== Integration Instructions for hydai.zsh-theme ===

To integrate ccusage into your hydai theme, choose one of these methods:

METHOD 1: Add as a segment (Recommended)
----------------------------------------
1. Edit ~/.oh-my-zsh/custom/themes/hydai.zsh-theme
2. Add 'ccusage' to your RIGHT_PROMPT_ELEMENTS:
   
   Line ~404: Change from:
   HYDAI_RIGHT_PROMPT_ELEMENTS=(longstatus history time)
   
   To:
   HYDAI_RIGHT_PROMPT_ELEMENTS=(longstatus ccusage history time)

3. Copy the prompt_ccusage function from this file to your theme file
   (anywhere before the build_right_prompt function)

4. Update the precmd function (line ~412) to include ccusage updates:
   
   Replace:
   precmd() {
     vcs_info
     vcs_info_hookadd set-message vcs-detect-changes
   }
   
   With:
   precmd() {
     vcs_info
     vcs_info_hookadd set-message vcs-detect-changes
     
     # Update ccusage if available
     if (( $+functions[ccusage_precmd] )); then
       ccusage_precmd
     fi
   }

METHOD 2: Add to RPROMPT directly (Simple)
------------------------------------------
1. Edit ~/.oh-my-zsh/custom/themes/hydai.zsh-theme
2. Change line ~425 from:
   RPROMPT='%{%f%b%k%}$(build_right_prompt)%{$reset_color%}'
   
   To:
   RPROMPT='$(prompt_ccusage_simple) %{%f%b%k%}$(build_right_prompt)%{$reset_color%}'

3. Copy the prompt_ccusage_simple function from this file to your theme file

METHOD 3: Configure in .zshrc (Easiest, but less integrated)
------------------------------------------------------------
Add this to your .zshrc AFTER loading oh-my-zsh:

# Override RPROMPT after theme loads
RPROMPT='$(ccusage_display) '$RPROMPT

Note: This method won't use your theme's styling.

=== Color Customization ===
You can customize colors in the prompt_ccusage function:
- Background: "237" (dark gray) - change to any color code
- Foreground: "white" - change to any color name or code

EOF