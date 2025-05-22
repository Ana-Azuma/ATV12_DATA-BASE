-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS sistema_gerenciamento;
USE sistema_gerenciamento;

-- Tabela Fornecedores
CREATE TABLE Fornecedores (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(100),
    Contato VARCHAR(100)
);

-- Tabela Clientes
CREATE TABLE Clientes (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(100),
    Email VARCHAR(100)
);

-- Tabela Estoque
CREATE TABLE Estoque (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Produto VARCHAR(100),
    Quantidade INT,
    ID_Fornecedor INT,
    FOREIGN KEY (ID_Fornecedor) REFERENCES Fornecedores(ID)
);

-- Tabela Pedidos
CREATE TABLE Pedidos (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Produto VARCHAR(100),
    Quantidade INT,
    ID_Cliente INT,
    Status VARCHAR(50) DEFAULT 'Pendente',
    DataPedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ID_Cliente) REFERENCES Clientes(ID)
);

-- Tabela Historico_Pedidos
CREATE TABLE Historico_Pedidos (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Produto VARCHAR(100),
    Quantidade INT,
    ID_Cliente INT,
    Status VARCHAR(50),
    DataPedido TIMESTAMP,
    FOREIGN KEY (ID_Cliente) REFERENCES Clientes(ID)
);

-- Inserindo Fornecedores
INSERT INTO Fornecedores (Nome, Contato) VALUES
('TechComponents Ltda', 'contato@techcomponents.com'),
('EletroSupplies S.A.', 'vendas@eletrosupplies.com'),
('ComponentesPro', 'comercial@componentespro.com'),
('MicroParts Brasil', 'pedidos@microparts.com.br');

-- Inserindo Clientes
INSERT INTO Clientes (Nome, Email) VALUES
('João Silva', 'joao.silva@email.com'),
('Maria Santos', 'maria.santos@email.com'),
('Pedro Oliveira', 'pedro.oliveira@email.com'),
('Ana Costa', 'ana.costa@email.com'),
('Carlos Ferreira', 'carlos.ferreira@email.com');

-- Inserindo produtos no Estoque
INSERT INTO Estoque (Produto, Quantidade, ID_Fornecedor) VALUES
('Resistor 1kΩ', 1000, 1),
('Capacitor 100µF', 500, 1),
('LED Verde 5mm', 800, 2),
('Transistor BC547', 300, 2),
('Arduino Uno R3', 50, 3),
('Protoboard 830 pontos', 75, 3),
('Jumpers Macho-Fêmea', 200, 4),
('Display LCD 16x2', 25, 4),
('Sensor Ultrassônico HC-SR04', 40, 1),
('Servo Motor SG90', 60, 2);

-- Inserindo Pedidos
INSERT INTO Pedidos (Produto, Quantidade, ID_Cliente, Status) VALUES
('Arduino Uno R3', 2, 1, 'Pendente'),
('LED Verde 5mm', 50, 2, 'Pendente'),
('Resistor 1kΩ', 100, 3, 'Pendente'),
('Display LCD 16x2', 3, 4, 'Pendente'),
('Servo Motor SG90', 5, 5, 'Pendente'),
('Capacitor 100µF', 20, 1, 'Pendente'),
('Protoboard 830 pontos', 2, 2, 'Pendente');

-- ============================================
-- CRIAÇÃO DE VIEWS
-- ============================================

-- View para mostrar pedidos com informações dos clientes
CREATE VIEW VIEW_Pedidos_Clientes AS
SELECT 
    p.ID as ID_Pedido,
    p.Produto,
    p.Quantidade,
    p.Status,
    p.DataPedido,
    c.Nome as Nome_Cliente,
    c.Email as Email_Cliente
FROM Pedidos p
INNER JOIN Clientes c ON p.ID_Cliente = c.ID;

-- View para mostrar estoque com informações dos fornecedores
CREATE VIEW VIEW_Estoque_Fornecedores AS
SELECT 
    e.ID as ID_Estoque,
    e.Produto,
    e.Quantidade as Estoque_Disponivel,
    f.Nome as Nome_Fornecedor,
    f.Contato as Contato_Fornecedor
FROM Estoque e
INNER JOIN Fornecedores f ON e.ID_Fornecedor = f.ID;

-- ============================================
-- STORED PROCEDURES
-- ============================================
DROP PROCEDURE IF EXISTS ProcessarPedido;

-- Procedure para processar pedido (verificar estoque e confirmar)
DELIMITER //
CREATE PROCEDURE ProcessarPedido(IN pedido_id INT)
BEGIN
    DECLARE produto_pedido VARCHAR(100);
    DECLARE quantidade_pedida INT;
    DECLARE estoque_disponivel INT;
    DECLARE cliente_id INT;
    DECLARE data_pedido TIMESTAMP;
    DECLARE estoque_id INT;
    
    -- Buscar informações do pedido
    SELECT Produto, Quantidade, ID_Cliente, DataPedido 
    INTO produto_pedido, quantidade_pedida, cliente_id, data_pedido
    FROM Pedidos 
    WHERE ID = pedido_id AND Status = 'Pendente';
    
    -- Verificar estoque disponível e obter ID do estoque
    SELECT ID, Quantidade INTO estoque_id, estoque_disponivel
    FROM Estoque 
    WHERE Produto = produto_pedido;
    
    -- Se há estoque suficiente
    IF estoque_disponivel >= quantidade_pedida THEN
        -- Atualizar estoque usando a chave primária
        UPDATE Estoque 
        SET Quantidade = Quantidade - quantidade_pedida 
        WHERE ID = estoque_id;
        
        -- Confirmar pedido usando a chave primária
        UPDATE Pedidos 
        SET Status = 'Confirmado' 
        WHERE ID = pedido_id;
        
        -- Registrar no histórico
        INSERT INTO Historico_Pedidos (Produto, Quantidade, ID_Cliente, Status, DataPedido)
        VALUES (produto_pedido, quantidade_pedida, cliente_id, 'Confirmado', data_pedido);
        
        SELECT 'Pedido confirmado com sucesso!' as Resultado;
    ELSE
        -- Pedido negado por falta de estoque usando a chave primária
        UPDATE Pedidos 
        SET Status = 'Negado - Estoque Insuficiente' 
        WHERE ID = pedido_id;
        
        -- Registrar no histórico
        INSERT INTO Historico_Pedidos (Produto, Quantidade, ID_Cliente, Status, DataPedido)
        VALUES (produto_pedido, quantidade_pedida, cliente_id, 'Negado - Estoque Insuficiente', data_pedido);
        
        SELECT CONCAT('Pedido negado! Estoque disponível: ', estoque_disponivel, ', Solicitado: ', quantidade_pedida) as Resultado;
    END IF;
END //
DELIMITER ;

-- ============================================
-- FUNCTION PARA VERIFICAR ESTOQUE
-- ============================================
-- Remover function se já existir
DROP FUNCTION IF EXISTS VerificarEstoque;

DELIMITER //
CREATE FUNCTION VerificarEstoque(produto_nome VARCHAR(100)) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE estoque_atual INT DEFAULT 0;
    
    SELECT Quantidade INTO estoque_atual
    FROM Estoque 
    WHERE Produto = produto_nome;
    
    RETURN COALESCE(estoque_atual, 0);
END //
DELIMITER ;

-- ============================================
-- TRIGGER PARA HISTÓRICO AUTOMÁTICO
-- ============================================
DROP TRIGGER IF EXISTS TriggerHistoricoPedidos;

DELIMITER //
CREATE TRIGGER TriggerHistoricoPedidos
AFTER UPDATE ON Pedidos
FOR EACH ROW
BEGIN
    IF NEW.Status != OLD.Status THEN
        INSERT INTO Historico_Pedidos (Produto, Quantidade, ID_Cliente, Status, DataPedido)
        VALUES (NEW.Produto, NEW.Quantidade, NEW.ID_Cliente, NEW.Status, NEW.DataPedido);
    END IF;
END //
DELIMITER ;

-- ============================================
-- EXEMPLOS DE TESTE
-- ============================================

-- Testando o sistema
SELECT '=== ESTADO INICIAL ===' as Info;

-- Visualizar estoque atual
SELECT 'ESTOQUE ATUAL:' as Info;
SELECT * FROM VIEW_Estoque_Fornecedores;

-- Visualizar pedidos pendentes
SELECT 'PEDIDOS PENDENTES:' as Info;
SELECT * FROM VIEW_Pedidos_Clientes WHERE Status = 'Pendente';

-- Processar alguns pedidos
SELECT '=== PROCESSANDO PEDIDOS ===' as Info;
CALL ProcessarPedido(1); -- Arduino Uno R3
CALL ProcessarPedido(2); -- LED Verde 5mm
CALL ProcessarPedido(3); -- Resistor 1kΩ

-- Verificar resultados
SELECT '=== ESTADO APÓS PROCESSAMENTO ===' as Info;

-- Estoque atualizado
SELECT 'ESTOQUE ATUALIZADO:' as Info;
SELECT * FROM VIEW_Estoque_Fornecedores;

-- Pedidos processados
SELECT 'PEDIDOS PROCESSADOS:' as Info;
SELECT * FROM VIEW_Pedidos_Clientes;

-- Histórico de pedidos
SELECT 'HISTÓRICO DE PEDIDOS:' as Info;
SELECT 
    h.ID,
    h.Produto,
    h.Quantidade,
    c.Nome as Cliente,
    h.Status,
    h.DataPedido
FROM Historico_Pedidos h
INNER JOIN Clientes c ON h.ID_Cliente = c.ID
ORDER BY h.DataPedido DESC;

-- Testando a função de verificar estoque
SELECT 'VERIFICAÇÃO DE ESTOQUE:' as Info;
SELECT 
    'Arduino Uno R3' as Produto,
    VerificarEstoque('Arduino Uno R3') as Estoque_Disponivel;

-- Produtos com estoque baixo (menos de 100 unidades)
SELECT 'PRODUTOS COM ESTOQUE BAIXO:' as Info;
SELECT * FROM VIEW_Estoque_Fornecedores WHERE Estoque_Disponivel < 100;

-- Clientes com pedidos confirmados
SELECT 'CLIENTES COM PEDIDOS CONFIRMADOS:' as Info;
SELECT DISTINCT c.Nome, c.Email
FROM Clientes c
INNER JOIN Pedidos p ON c.ID = p.ID_Cliente
WHERE p.Status = 'Confirmado';

-- Relatório de vendas por produto
SELECT 'RELATÓRIO DE VENDAS:' as Info;
SELECT 
    Produto,
    COUNT(*) as Total_Pedidos,
    SUM(Quantidade) as Quantidade_Total,
    SUM(CASE WHEN Status = 'Confirmado' THEN Quantidade ELSE 0 END) as Quantidade_Confirmada
FROM Historico_Pedidos
GROUP BY Produto
ORDER BY Quantidade_Total DESC;