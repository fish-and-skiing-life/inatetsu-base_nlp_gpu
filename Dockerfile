FROM ubuntu:18.04

RUN apt-get -qq update && apt install -y --no-install-recommends build-essential sudo


EXPOSE 8888

RUN apt-get update && apt-get install -y \
	python3 \ 
	python3-pip \
	mecab \ 
	libmecab-dev \
	mecab-ipadic-utf8 \
	wget \ 
	make \
	file \ 
	unzip \
	git \ 
	curl \
    build-essential \
    gfortran \
    libblas-dev \
    liblapack-dev \
    libxft-dev \
    && rm -rf /var/lib/apt/lists/*


# Install MeCab
RUN pip3 install mecab-python3

# Install mecab-ipadic-NEologd
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git /tmp/neologd \
  && /tmp/neologd/bin/install-mecab-ipadic-neologd -n -a -y \
  && sed -i -e "s|^dicdir.*$|dicdir = /usr/lib/mecab/dic/mecab-ipadic-neologd|" /etc/mecabrc \
  && rm -rf /tmp/neologd

 # Install neologdn
RUN pip3 install neologdn

RUN pip3 install --upgrade pyzmq --install-option="--zmq=bundled" && \
    pip3 install --upgrade jupyterlab && \
    pip3 install --upgrade \
    numpy \
    scipy \
    scikit-learn \
    matplotlib \
    pandas \
    mecab-python3 \
    neologdn \
    gensim 

# Install CRF++
RUN wget -O /tmp/CRF++-0.58.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ" \
  && cd /tmp \
  && tar zxf CRF++-0.58.tar.gz \
  && cd CRF++-0.58 \
  && ./configure \
  && make \
  && make install \
  && cd / \
  && rm /tmp/CRF++-0.58.tar.gz \
  && rm -rf /tmp/CRF++-0.58 \
  && ldconfig

# Install CaboCha
RUN cd /tmp \
	&& FILE_ID=0B4y35FiV1wh7SDd1Q1dUQkZQaUU \
	&& FILE_NAME=cabocha-0.69.tar.bz2 \
	&& curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${FILE_ID}" > /dev/null \
	&& CODE="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"   \
	&& curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${CODE}&id=${FILE_ID}" -o ${FILE_NAME}  \
	&& tar jxf cabocha-0.69.tar.bz2  \
    && cd cabocha-0.69 \
    && export CPPFLAGS=-I/usr/local/include \
    && ./configure --with-mecab-config=`which mecab-config` --with-charset=utf8 \
    && make \
    && make install 
   
RUN cd /tmp \
	&& cd cabocha-0.69 \
    && cd python \
    && python3 setup.py build \
    && python3 setup.py install 

# LAPACK/BLAS (scikit-learnで必要)
RUN cd /tmp \
    && wget http://www.netlib.org/lapack/lapack-3.8.0.tar.gz \
    && tar zxf lapack-3.8.0.tar.gz \
    && cd lapack-3.8.0/ \
    && cp make.inc.example make.inc \
    && make blaslib \
    && make lapacklib \
    && cp librefblas.a /usr/lib/libblas.a \
    && cp liblapack.a /usr/lib/liblapack.a \
    && cd / \
    && rm -rf /tmp/*

# Install fastText
RUN pip3 install git+https://github.com/facebookresearch/fastText.git

# Install Janome
RUN pip3 install janome

# machine learning library
RUN pip3 install tensorflow-gpu \
	 keras 

RUN pip3 install torchvision


ENTRYPOINT jupyter lab --ip=0.0.0.0 --allow-root --no-browser
