FROM janx/ubuntu-dev

# Install Chromium's depot_tools.
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH $PATH:/home/user/depot_tools
ENV GYP_CHROMIUM_NO_ACTION 1
RUN cat << EOD >> .bashrc

# Add Chromium's depot_tools to the PATH.
export PATH="\$PATH:/home/user/depot_tools"

# The next line enables bash completion for git cl.
if [ -f "/home/user/depot_tools/git_cl_completion.sh" ]; then
  . "/home/user/depot_tools/git_cl_completion.sh"
fi

# Disable gyp_chromium for faster updates.
export GYP_CHROMIUM_NO_ACTION=1

EOD

# Create the Chromium directory.
WORKDIR /home/user/chromium

# Download Chromium's source code.
RUN fetch --nohooks chromium

# Install Chromium build dependencies (with administrator privileges).
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections \
 && sudo src/build/install-build-deps.sh --no-prompt --no-arm --no-chromeos-fonts --no-nacl
RUN cd /tmp \
 && wget https://launchpad.net/ubuntu/+archive/primary/+files/libgcrypt11_1.5.3-2ubuntu4.2_amd64.deb \
 && sudo dpkg -i libgcrypt11_1.5.3-2ubuntu4.2_amd64.deb \
 && rm -f libgcrypt11_1.5.3-2ubuntu4.2_amd64.deb

# Configure Cloud9 to use Chromium's source directory as workspace (-w).
RUN sudo sed -i "s/-w \/home\/user/-w \/home\/user\/chromium\/src/" /etc/supervisord.conf

# Update Chromium third_party repos and run pre-compile hooks.
WORKDIR /home/user/chromium/src
RUN gclient runhooks --jobs=18

# Configure Chromium build.
RUN gn gen out/Default --args="enable_nacl=false is_component_build=true"

# Configure Janitor for Chromium
COPY janitor.json /home/user/
RUN sudo chown user:user /home/user/janitor.json
