
FROM brmather/pygplates-compile:22

# install dependencies for pygplates
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    python2.7-dev \
    python-pip \
    xvfb \
    libfreetype6-dev \
    libfontconfig1-dev \
    cmake \
    git \
    gfortran \
    wget && \
    apt-get remove -yq python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# libgdal-dev \
# libgdal20 \
# gdal-abi-2-2-3 \




# install all the python and ipython notebook requirements
RUN python2 -m pip install --no-cache-dir setuptools wheel Cython && \
    python2 -m pip install --upgrade --no-cache-dir numpy scipy matplotlib && \
    python2 -m pip install --no-cache-dir --upgrade \
        pandas \
        sympy \
        boost \
        pillow \
        cartopy \
        nose && \
    python2 -m pip install git+https://github.com/matplotlib/basemap.git && \
    python2 -m pip install --no-cache-dir \
        jupyter \
        ipyparallel \
        stripy && \
    rm -rf /tmp/pip-*

RUN wget https://github.com/matplotlib/basemap/archive/master.zip && \
    unzip master.zip && \
    cd basemap-master && \
    python2 -m pip install --no-cache-dir . && \
    cd .. && \
    rm -rf master.zip basemap-master

WORKDIR /opt/work/


# remove python3 installation
# RUN apt-get remove -yq python3 && \
#     apt-get autoremove -yq && \
#     apt-get clean

# Install non-linear optimisation package, with options to import into python
#RUN wget http://ab-initio.mit.edu/nlopt/nlopt-2.4.2.tar.gz
#RUN tar -xvzf nlopt-2.4.2.tar.gz
#RUN cd nlopt-2.4.2 && ./configure --enable-shared && make && make install

ENV NB_USER jovyan
RUN useradd -ms /bin/bash jovyan

# Set python path to find pygplates and nlopt


RUN git clone https://github.com/tonysyu/mpltools.git mpltools && \
    cd mpltools && python setup.py install && \
    export LD_LIBRARY_PATH=/usr/local/lib && \
    rm -rf mpltools


# COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
# RUN chown -R $NB_USER:root /home/$NB_USER/.jupyter

# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


# add a notebook profile
RUN mkdir -p -m 700 /root/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> /root/.jupyter/jupyter_notebook_config.py


EXPOSE 8888
EXPOSE 9999

# Add pygplates stuff to PYTHONPATH
ENV PYTHONPATH ${PYTHONPATH}:/usr/lib:/usr/lib/pygplates/revision18/
ADD --chown=jovyan:jovyan . /home/$NB_USER/

# More dependencies...

# Plate Tectonic Tools
RUN python2 -m pip install --no-cache-dir \
    git+https://github.com/EarthByte/PlateTectonicTools.git \
    && rm -rf PlateTectonicTools

# pyBacktrack
RUN python2 -m pip install --no-cache-dir \
    healpy \
    git+https://github.com/EarthByte/pyBacktrack.git \
    && rm -rf /tmp/pip-*

# Copy GPlatesClassStruggle to Resources directory
RUN git clone https://github.com/siwill22/GPlatesClassStruggle.git && \
    mkdir /home/$NB_USER/Resources/GPlatesClassStruggle && \
    mv GPlatesClassStruggle/*.py /home/$NB_USER/Resources/GPlatesClassStruggle/ && \
    rm -rf GPlatesClassStruggle

# Copy gwstools
RUN git clone https://github.com/siwill22/gwstools.git && \
    mv gwstools/*.py /home/$NB_USER/Resources/GPlatesClassStruggle/ && \
    rm -rf gwstools

# Copy platetree
RUN git clone https://github.com/siwill22/platetree.git && \
    mv platetree/*.py /home/$NB_USER/Resources/GPlatesClassStruggle/ && \
    rm -rf platetree

# Copy ATOM tools
RUN git clone https://github.com/siwill22/atom_utils.git && \
    mv atom_utils/*.py /home/$NB_USER/Resources/GPlatesClassStruggle/ && \
    rm -rf atom_utils



# change ownership of everything
RUN chown -R jovyan:jovyan /home/jovyan
USER jovyan


VOLUME /home/jovyan/workspace
WORKDIR /home/jovyan/
# Trust all notebooks
RUN find -name \*.ipynb  -print0 | xargs -0 jupyter trust


# launch notebook
CMD ["jupyter", "notebook", "--ip='0.0.0.0'", "--NotebookApp.token='' ", "--no-browser"]
