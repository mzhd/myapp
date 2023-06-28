# 第一阶段的FROM,名为 build，为下面使用
FROM rust as build 

# 创建空项目,名称与要发布的项目名相同
RUN USER=root cargo new --bin myapp
WORKDIR /myapp

# 覆盖清单，用来编译依赖项
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# 构建依赖并缓存依赖项
RUN cargo build --release 
RUN rm src/*.rs

# 覆盖源代码和其它文件
COPY ./src ./src

# 删除上面构建的二进制文件，然后编译源码，注意是源码不是依赖项
RUN rm ./target/release/deps/myapp*

# 只会编译源码，依赖项已编译好了
RUN cargo build --release

# 最终的FROM，只包含可运行的二进制文件
#使用debian:buster-slim会报错，因为没有openssl
#FROM debian:buster-slim
#FROM alpine
FROM rust

# 指定工作目录为app，这样文件就都放在了app中，默认为根目录
WORKDIR /app

# 复制构建阶段中的二进制文件到 WORKDIR 目录下
COPY --from=build /myapp/target/release/myapp .

# 复制配置文件，必须有
# COPY ./config ./config
# COPY ./.env ./.env
# COPY ./diesel.toml ./diesel.toml
COPY ./Rocket.toml ./Rocket.toml

# 运行二进制文件
CMD ["./myapp"]