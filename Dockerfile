FROM library/ubuntu:xenial

MAINTAINER ludd@cbs.dtu.dk

WORKDIR /srv/www/htdocs

RUN useradd developer
RUN echo "developer:docker" | chpasswd

# Set environment varaibles
ENV TERM=xterm
ENV DEBUG='true'
ENV CODE_BASE=development
ENV ENVIRONMENT=docker

# Add favourite commands
RUN echo 'alias ..="cd .."' > /root/.bash_aliases
RUN echo 'alias ll="ls -alF"' >> /root/.bash_aliases
RUN echo 'alias pyc="find $(pwd) -type f -name *.pyc -delete"' >> /root/.bash_aliases
RUN echo 'alias pyo="find $(pwd) -type f -name *.pyo -delete"' >> /root/.bash_aliases

# Web socket setup
RUN mkdir -p /var/run/app
RUN chown www-data:www-data /var/run/app

# Install dependencies
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    apache2 \
    curl \
    git \
    htop \
    iputils-ping \
    libapache2-mod-php \
    libapache2-mod-wsgi \
    mc \
    nginx \
    npm \
    openssh-server \
    php-apcu \
    php-gettext \
    phppgadmin \
    php7.0 \
    php7.0-curl \
    php7.0-gd \
    php7.0-fpm \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-tokenizer \
    php7.0-mysql \
    php7.0-pdo \
    php7.0-xml \
    php7.0-xmlrpc \
    php7.0-zip \
    python-pip \
    python-psycopg2 \
    python2.7 \
    libapache2-mod-php7.0 \
    rabbitmq-server \
    ruby \
    ruby-dev \
    supervisor \
    tig \
    vim \
    wget


# Install PHP Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH="${PATH}:~/.composer/vendor/bin"

# Install Laravel
RUN composer global require "laravel/installer"

# Install phpMyAdmin
RUN wget https://github.com/phpmyadmin/phpmyadmin/archive/master.zip && unzip master.zip && rm master.zip && mv phpmyadmin-master/ /usr/share/phpmyadmin
RUN composer install -d /usr/share/phpmyadmin

# Setup PHP-FPM
RUN sed -ie 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini

# Enforce reading PHP files in the first place
RUN sed -ie 's/index.php //g' /etc/apache2/mods-enabled/dir.conf
RUN sed -ie 's/DirectoryIndex/DirectoryIndex index.php/g' /etc/apache2/mods-enabled/dir.conf

# Enable /srv
RUN sed -i "170,174 s/^#//" /etc/apache2/apache2.conf

# Allow .htaccess -wordpress requires this!
RUN sed -i "166,172 s/None/All/" /etc/apache2/apache2.conf

# Setup phpPgAdmin
RUN ln -s /usr/share/phppgadmin /srv/www/phpPgAdmin
RUN ln -s /usr/share/phpmyadmin /srv/www/phpMyAdmin

# phpMyAdmin Apache conf !!! CHANGE IN PRODUCTION !!!
RUN echo '<VirtualHost *:80>\n\tServerName pma.dev\n\tServerAlias pma.dev\n\tDocumentRoot /srv/www/phpMyAdmin\n\t<Directory /srv/www/phpMyAdmin>\n\t\tOrder allow,deny\n\t\tAllow from all\n\t</Directory>\n</VirtualHost>\n' > /srv/www/phpMyAdmin/pma.apache.conf
RUN ln -s /srv/www/phpMyAdmin/pma.apache.conf /etc/apache2/sites-available/pma.apache.conf
RUN ln -s /etc/apache2/sites-available/pma.apache.conf /etc/apache2/sites-enabled/pma.apache.conf

# phpPgAdmin Apache conf !!! CHANGE IN PRODUCTION !!!
RUN echo '<VirtualHost *:80>\n\tServerName ppa.dev\n\tServerAlias ppa.dev\n\tDocumentRoot /srv/www/phpPgAdmin\n\t<Directory /srv/www/phpPgAdmin>\n\t\tOrder allow,deny\n\t\tAllow from all\n\t</Directory>\n</VirtualHost>\n' > /srv/www/phpPgAdmin/ppa.apache.conf
RUN ln -s /srv/www/phpPgAdmin/ppa.apache.conf /etc/apache2/sites-available/ppa.apache.conf
RUN ln -s /etc/apache2/sites-available/ppa.apache.conf /etc/apache2/sites-enabled/ppa.apache.conf

# phpMyAdmin Nginx conf !!! CHANGE IN PRODUCTION !!!
RUN echo 'server {\n\tlisten 80;\n\tserver_name pma.dev;\n\troot /srv/www/phpMyAdmin;\n\n\tindex index.php index.html index.htm;\n\n\tlocation ~ \.php$ {\n\t\ttry_files $uri =404;\n\t\tfastcgi_split_path_info ^(.+\.php)(/.+)$;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t\tfastcgi_index index.php;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tinclude fastcgi_params;\n\t}\n }' > /srv/www/phpMyAdmin/pma.nginx.conf
RUN ln -s /srv/www/phpMyAdmin/pma.nginx.conf /etc/nginx/sites-available/pma.nginx.conf
RUN ln -s /etc/nginx/sites-available/pma.nginx.conf /etc/nginx/sites-enabled/pma.nginx.conf

# phpPgAdmin Nginx conf !!! CHANGE IN PRODUCTION !!!
RUN echo 'server {\n\tlisten 80;\n\tserver_name ppa.dev;\n\troot /srv/www/phpPgAdmin;\n\n\tindex index.php index.html index.htm;\n\n\tlocation ~ \.php$ {\n\t\ttry_files $uri =404;\n\t\tfastcgi_split_path_info ^(.+\.php)(/.+)$;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t\tfastcgi_index index.php;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tinclude fastcgi_params;\n\t}\n }' > /srv/www/phpPgAdmin/ppa.nginx.conf
RUN ln -s /srv/www/phpPgAdmin/ppa.nginx.conf /etc/nginx/sites-available/ppa.nginx.conf
RUN ln -s /etc/nginx/sites-available/ppa.nginx.conf /etc/nginx/sites-enabled/ppa.nginx.conf

# Install pip
RUN pip install --upgrade pip
RUN pip install uwsgi
RUN pip install gunicorn

# Install nodesjs
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g bower
RUN npm install -g gulp-cli

# Install jekyll
RUN gem install jekyll bundler

# Clean installation
RUN apt-get autoremove -y

# Settings
RUN a2enmod ssl
RUN a2enmod rewrite
RUN phpenmod mcrypt
RUN phpenmod mbstring
