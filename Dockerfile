FROM ubuntu:latest

MAINTAINER Juan Galarza juan.galarza@jyu.fi

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y \
	apt-transport-https \
	apt-utils \
	automake \
	build-essential \
	bzip2 \
	ca-certificates \
	cmake \
	curl \
	default-jre \
	ed \
	fort77 \
	ftp \
	g++ \
	gcc \
	gfortran \
	git \
	gnupg2 \
	gsfonts \
	less \
	libblas-dev \
	libbz2-dev \
	libcairo2-dev \
	libcurl4-openssl-dev \
	libdb-dev \
	libghc-zlib-dev \
	libjpeg-dev \
	liblzma-dev \
	libncurses-dev \
	libncurses5-dev \
	libpcre3-dev \
	libpng-dev \
	libreadline-dev \
	libssl-dev \
	libx11-dev \
	libxml2-dev \
	libxt-dev \
	libzmq3-dev \
	locales \
	make \
	nano \
	perl \
	pkg-config libtbb-dev \
	python3 \
	python3-dev \
	python3-distutils \
	python3-pip \
	python3-setuptools \
	rsync \
	texlive-latex-base \
	tzdata \
	unzip \
	vim-tiny \
	wget \
	x11-common \
	zlib1g-dev \

&& rm -rf /var/lib/apt/lists/*

#### Perl libs
RUN curl -L https://cpanmin.us | perl - App::cpanminus
RUN cpanm install DB_File
RUN cpanm install URI::Escape

#### set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin   


#### some python modules
RUN ln -sf /usr/bin/python3 /usr/bin/python
RUN pip3 install numpy
RUN pip3 install HTSeq

#####
# Install R

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8


WORKDIR $SRC

ENV R_VERSION=R-3.6.3

RUN curl https://cran.r-project.org/src/base/R-3/$R_VERSION.tar.gz -o $R_VERSION.tar.gz && \
        tar xvf $R_VERSION.tar.gz && \
        cd $R_VERSION && ./configure && make && make install


RUN R -e 'install.packages("BiocManager", repos="http://cran.us.r-project.org")'
RUN R -e 'BiocManager::install("tidyverse")'
RUN R -e 'BiocManager::install("edgeR")'
RUN R -e 'BiocManager::install("DESeq2")'
RUN R -e 'BiocManager::install("ape")'
RUN R -e 'BiocManager::install("ctc")'
RUN R -e 'BiocManager::install("gplots")'
RUN R -e 'BiocManager::install("Biobase")'
RUN R -e 'BiocManager::install("qvalue")'
RUN R -e 'BiocManager::install("goseq")'
RUN R -e 'BiocManager::install("Glimma")'
RUN R -e 'BiocManager::install("ROTS")'
RUN R -e 'BiocManager::install("GOplot")'
RUN R -e 'BiocManager::install("argparse")'
RUN R -e 'BiocManager::install("fastcluster")'
RUN R -e 'BiocManager::install("DEXSeq")'
RUN R -e 'BiocManager::install("tximport")'
RUN R -e 'BiocManager::install("tximportData")'


#### FASTQC
RUN wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip && \
    unzip fastqc_v0.11.5.zip && \
    chmod 755 /usr/local/src/FastQC/fastqc && \
    ln -s /usr/local/src/FastQC/fastqc $BIN/.

#### MultiQC	
RUN pip3 install git+https://github.com/ewels/MultiQC.git


## bowtie
WORKDIR $SRC
RUN wget https://sourceforge.net/projects/bowtie-bio/files/bowtie/1.2.1.1/bowtie-1.2.1.1-linux-x86_64.zip/download -O bowtie-1.2.1.1-linux-x86_64.zip && \
        unzip bowtie-1.2.1.1-linux-x86_64.zip && \
	mv bowtie-1.2.1.1/bowtie* $BIN

#### Bowtie2
RUN wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.4.1/bowtie2-2.3.4.1-linux-x86_64.zip/download -O bowtie2-2.3.4.1-linux-x86_64.zip && \
    unzip bowtie2-2.3.4.1-linux-x86_64.zip && \
    mv bowtie2-2.3.4.1-linux-x86_64/bowtie2* $BIN && \
    rm *.zip && \
    rm -r bowtie2-2.3.4.1-linux-x86_64
    

## Jellyfish
RUN wget https://github.com/gmarcais/Jellyfish/releases/download/v2.2.7/jellyfish-2.2.7.tar.gz && \
    tar xvf jellyfish-2.2.7.tar.gz && \
    cd jellyfish-2.2.7/ && \
    ./configure && make && make install


#### Kallisto
RUN wget https://github.com/pachterlab/kallisto/releases/download/v0.43.1/kallisto_linux-v0.43.1.tar.gz && \
    tar xvf kallisto_linux-v0.43.1.tar.gz && \
    mv kallisto_linux-v0.43.1/kallisto $BIN
    
    
#### Samtools
RUN wget https://github.com/samtools/samtools/releases/download/1.11/samtools-1.11.tar.bz2 && \
    tar xvf samtools-1.11.tar.bz2 && \
    cd samtools-1.11 && \
    ./configure && make && make install
    
    
#### RSEM
RUN mkdir /usr/local/lib/site_perl
RUN wget https://github.com/deweylab/RSEM/archive/v1.3.0.tar.gz && \
	 tar xvf v1.3.0.tar.gz && \
     cd RSEM-1.3.0 && \
     make && \
     cp rsem-* $BIN && \
     cp convert-sam-for-rsem $BIN && \
     cp rsem_perl_utils.pm /usr/local/lib/site_perl/ && \
     cd ../ && rm -r RSEM-1.3.0
 
#### Picard tools

RUN wget https://github.com/broadinstitute/picard/releases/download/2.20.3/picard.jar
ENV PICARD_HOME $SRC


#### Trinity

RUN ln -sf /usr/bin/python3 /usr/bin/python

ENV TRINITY_VERSION="2.11.0"
ENV TRINITY_CO="e903e224e2df93f1fabafb1abe02d7db05255a5e"

RUN git clone --recursive https://github.com/trinityrnaseq/trinityrnaseq.git && \
    cd trinityrnaseq && \
    git checkout ${TRINITY_CO} && \
    git submodule init && git submodule update && \
    git submodule foreach --recursive git submodule init && \
    git submodule foreach --recursive git submodule update && \
    rm -rf ./trinity_ext_sample_data && \
    make && make plugins && \
    make install && \
    cd ../ && rm -r trinityrnaseq

ENV TRINITY_HOME /usr/local/bin/trinityrnaseq
ENV PATH=${TRINITY_HOME}:${PATH}

#### Trimmomatic

ENV APP_NAME=Trimmomatic
ENV VERSION=0.39
ENV DEST=/usr/local/bin/$APP_NAME/
ENV PATH=$DEST/$VERSION:$PATH
ENV TRIMMOMATIC=$DEST/$VERSION/trimmomatic-$VERSION.jar
ENV ADAPTERPATH=$DEST/$VERSION/adapters


RUN apt-get install -y unzip java ; \
    curl -L -o $APP_NAME-$VERSION.zip \
    http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-$VERSION.zip ; \
    unzip $APP_NAME-$VERSION.zip ; \
    rm -f $APP_NAME-$VERSION.zip ; \ 
    mkdir -p /usr/share/licenses/$APP_NAME-$VERSION ; \
    cp $APP_NAME-$VERSION/LICENSE /usr/share/licenses/$APP_NAME-$VERSION/ ; \
    mkdir -p $DEST ; \
    mv $APP_NAME-$VERSION  $DEST/$VERSION ;
    
####  Hmmer

RUN wget http://eddylab.org/software/hmmer/hmmer-3.1b2.tar.gz && tar xvfz hmmer-3.1b2.tar.gz && \
	cd hmmer-3.1b2 && ./configure && make && make install && cd ..

#### CD-Hit

RUN wget https://github.com/weizhongli/cdhit/releases/download/V4.8.1/cd-hit-v4.8.1-2019-0228.tar.gz && \
	tar xfz cd-hit-v4.8.1-2019-0228.tar.gz && \
	rm cd-hit-v4.8.1-2019-0228.tar.gz && \
	cd cd-hit-v4.8.1-2019-0228 && \
	make && \
	cd cd-hit-auxtools && \
	make

ENV PATH=${PATH}:/usr/src/cd-hit-v4.8.1-2019-0228:/usr/src/cd-hit-v4.8.1-2019-0228/cd-hit-auxtools

#### blast

RUN wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.11.0+-x64-linux.tar.gz && \
    tar xvf ncbi-blast-2.11.0+-x64-linux.tar.gz && \
    cp ncbi-blast-2.11.0+/bin/* $BIN && \
    rm -r ncbi-blast-2.11.0+


# some cleanup

RUN rm -r ${R_VERSION} *.tar.gz *.bz2

RUN apt-get clean
