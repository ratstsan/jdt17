CREATE TABLE penjual (
    kode_penjual VARCHAR(5) PRIMARY KEY,
    nama_penjual VARCHAR(100)
);

CREATE TABLE pembeli (
    kode_pembeli VARCHAR(5) PRIMARY KEY,
    nama_pembeli VARCHAR(100)
);

CREATE TABLE alamat (
    kode_alamat VARCHAR(5) PRIMARY KEY,
    kode_pembeli VARCHAR(5),
    nama_penerima VARCHAR(100),
    jalan TEXT,
    provinsi VARCHAR(100),
    kota VARCHAR(100),
    negara VARCHAR(100),
    kodepos VARCHAR(10),

    FOREIGN KEY (kode_pembeli)
    REFERENCES pembeli(kode_pembeli)
);

CREATE TABLE produk (
    kode_produk VARCHAR(10) PRIMARY KEY,
    nama_produk VARCHAR(100),
    berat INT,
    harga BIGINT,
    kode_penjual VARCHAR(5),

    FOREIGN KEY (kode_penjual)
    REFERENCES penjual(kode_penjual)
);

CREATE TABLE metode_pembayaran (
    kode_pembayaran VARCHAR(5) PRIMARY KEY,
    metode_pembayaran VARCHAR(50)
);

CREATE TABLE kurir (
    kode_kurir VARCHAR(5) PRIMARY KEY,
    nama_kurir VARCHAR(100)
);

CREATE TABLE orders (
    kode_order VARCHAR(10) PRIMARY KEY,
    tanggal DATE,
    kode_alamat VARCHAR(5),
    total_ongkos BIGINT,
    biaya_jasa BIGINT,
    kode_pembayaran VARCHAR(5),
    kode_kurir VARCHAR(5),

    FOREIGN KEY (kode_alamat)
    REFERENCES alamat(kode_alamat),

    FOREIGN KEY (kode_pembayaran)
    REFERENCES metode_pembayaran(kode_pembayaran),

    FOREIGN KEY (kode_kurir)
    REFERENCES kurir(kode_kurir)
);

CREATE TABLE order_detail (
    id SERIAL PRIMARY KEY,
    kode_order VARCHAR(10),
    kode_produk VARCHAR(10),
    jumlah INT,

    FOREIGN KEY (kode_order)
    REFERENCES orders(kode_order),

    FOREIGN KEY (kode_produk)
    REFERENCES produk(kode_produk)
);

INSERT INTO penjual VALUES
('GO', 'Galeri Olahraga'),
('HS', 'Hello Store');

INSERT INTO pembeli VALUES
('JM', 'Joko Morro'),
('EK', 'Eko Kurniawan');

INSERT INTO alamat VALUES
('BN', 'JM', 'Budi Nugraha', 'Jalan raya xxx', 'DKI Jakarta', 'Jakarta', 'Indonesia', '433333'),
('RL', 'EK', 'Rully', 'Jalan raya baru', 'Jawa Barat', 'Bandung', 'Indonesia', '432434');

INSERT INTO produk VALUES
('P0001', 'Bola Basket Size 7', 2300, 177900, 'GO'),
('P0002', 'Bola Basket Size 5', 500, 98900, 'GO'),
('P0003', 'Pentil Pompa Bola', 54, 9900, 'GO'),
('P0004', 'Pompa Bola', 198, 43900, 'GO'),
('P0005', 'Apple iPhone Pro Max', 1000, 25000000, 'HS'),
('P0006', 'Apple Watch 8', 2000, 8000000, 'HS');

INSERT INTO metode_pembayaran VALUES
('DO', 'Debit Online'),
('CC', 'Credit Card');

INSERT INTO kurir VALUES
('SG', 'Sicepat - Gokil'),
('JN', 'JNE');

INSERT INTO orders VALUES
('12345', '2023-04-11', 'BN', 60000, 1000, 'DO', 'SG'),
('11111', '2023-04-12', 'RL', 100000, 1000, 'CC', 'JN'),
('22222', '2023-04-13', 'BN', 60000, 1000, 'DO', 'SG');

INSERT INTO order_detail (kode_order, kode_produk, jumlah) VALUES
('12345', 'P0001', 2),
('12345', 'P0002', 1),
('12345', 'P0003', 1),
('12345', 'P0004', 1),
('11111', 'P0005', 1),
('11111', 'P0006', 1),
('22222', 'P0001', 2);