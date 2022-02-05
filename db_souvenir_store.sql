begin;

-- domínio de texto
create domain d_txt as varchar(100) not null;

-- domínio de criptografia
create domain d_crypt as varchar(60) not null;

-- universos possíveis do pagamento
create type t_pay as enum ('CC', 'BOL');

comment on type t_pay is 'CC - Cartão de Crédito, BOL - Boleto Bancário';

-- universos de status do pedido
create type t_status as enum ('A', 'F');

comment on type t_status is 'A - Em aberto (Está a caminho), F - Fechado (Pedido entregue)';

-- ufs dos estados do Brasil
create type t_uf as enum ('AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF',
'ES','GO','MA','MG','MS','MT','PA','PB','PE','PI','PR','RJ','RN','RO',
'RR','RS','SC','SE','SP','TO');

create table usuario(
    codigo serial,
    nome d_txt,
    sobrenome d_txt,
    email d_txt unique,
    cpf d_crypt unique,
    senha d_crypt,
    constraint pk_usr primary key (codigo)
);

create table endereco(
    codigo serial,
    numero_casa integer not null,
    complemento varchar(50) not null,
    referencia varchar(200) default 'Não informada',
    codigo_rua integer not null,
    codigo_usuario integer not null,
    constraint pk_end primary key (codigo)
);

create table rua(
    codigo serial,
    nome d_txt,
    codigo_bairro integer not null,
    constraint pk_rua primary key (codigo)
);

create table bairro(
  codigo serial,
  nome d_txt,
  codigo_cidade integer not null,
  constraint pk_br primary key (codigo)
);

create table cidade(
    codigo serial,
    nome d_txt,
    cep char(8) not null check (cep ~ '^[\d]{8}$'),
    codigo_estado integer not null,
    constraint pk_cid primary key (codigo)
);

create table estado(
    codigo serial,
    nome d_txt,
    uf t_uf not null,
    constraint pk_est primary key (codigo)
);

create table compra(
    numero_pedido serial, -- número de pedido
    codigo_usuario integer not null,
    codigo_produto integer not null,
    codigo_endereco integer not null,
    data_ped timestamp default current_timestamp,
    data_pag date,
    pagamento t_pay not null,
    quantidade smallint not null,
    valor money not null,
    serv_ent smallint not null, -- serviço de entrega
    status_pedido t_status default 'A',
    constraint pk_cp primary key (codigo_usuario, codigo_produto, data_ped)
);

create table produto(
    codigo serial,
    nome d_txt,
    descricao varchar(200) default 'Sem descrição',
    quantidade smallint not null,
    valor money not null,
    url_img varchar(100) not null,
    constraint pk_prod primary key (codigo)
);

create table produto_categoria (
    codigo_produto integer not null,
    codigo_categoria integer not null,
    constraint pk_prod_cat primary key (codigo_produto, codigo_categoria)
);

create table categoria(
    codigo serial,
    nome d_txt,
    constraint pk_cat primary key (codigo)
);

create table servico_entrega(
    codigo serial,
    nome d_txt,
    valor money not null,
    constraint pk_se primary key (codigo)
);


/* CHAVES ESTRANGEIRAS -----
    Padrão usado nos comentários: chave estrangeira -> chave primária*/

-- endereco -> usuario
alter table endereco
    add constraint fk_end_usr
        foreign key (codigo_usuario) references usuario(codigo);

-- endereço -> rua
alter table endereco
    add constraint fk_end_rua
        foreign key (codigo_rua) references rua(codigo);

-- rua -> bairro
alter table rua
    add constraint fk_rua_br
        foreign key (codigo_bairro) references bairro(codigo);

-- bairro -> cidade
alter table bairro
    add constraint fk_br_cid
        foreign key (codigo_cidade) references cidade(codigo);

-- cidade -> estado
alter table cidade
    add constraint fk_cid_est
        foreign key (codigo_estado) references estado(codigo);

-- compra -> usuario
alter table compra
    add constraint fk_cp_usr
        foreign key (codigo_usuario) references usuario(codigo);

-- compra -> produto
alter table compra
    add constraint fk_cp_pd
        foreign key (codigo_produto) references produto(codigo);

-- compra -> servico_entrega
alter table compra
    add constraint fk_cp_se
        foreign key (serv_ent) references servico_entrega(codigo);

-- produto_categoria -> produto
alter table produto_categoria
    add constraint fk_pCat_prod
        foreign key (codigo_produto) references produto(codigo);

-- produto_categoria -> categoria
alter table produto_categoria
    add constraint fk_pCat_cat
        foreign key (codigo_categoria) references categoria(codigo);

-- compra -> endereco
alter table compra
    add constraint fk_compra_end
        foreign key (codigo_endereco) references endereco(codigo);

commit;

--é necessário criar uma extensão hstore para uso posterior
create extension hstore;

--inserindo coluna do tipo hstore na tabela produto
alter table produto
    add column especificacoes hstore;

--motivo = consulta complexa e bastante utilizada
create view vw_usuario_endereco as
    select u.codigo as codigo_usr, u.nome usuario, en.*, r.nome rua, b.nome bairro, c.nome cidade, c.cep, es.nome estado , es.uf  from usuario as u
        join endereco as en on u.codigo = en.codigo_usuario
        join rua as r on en.codigo_rua = r.codigo
        join bairro as b on r.codigo_bairro = b.codigo
        join cidade as c on b.codigo_cidade = c.codigo
        join estado as es on c.codigo_estado = es.codigo;

alter table servico_entrega
    add column prazo varchar(50) not null;

comment on servico_entrega.prazo is 'Não é o prazo exato, só o mediano que foi estipulado pela transportadora';

--grande número de usuários com inicial de nome D
create index idx_usuario_nome on usuario (nome) where nome like  'D%';

create index idx_produto on produto using hash(codigo);



