-- SmartKrishi Database Schema for Windows Setup
-- Run this file after creating the database

-- Create database (run this separately first)
-- CREATE DATABASE smartkrishi;

-- Connect to smartkrishi database before running below commands
-- \c smartkrishi

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table for farmer profiles
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  phone VARCHAR(15) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  language VARCHAR(10) DEFAULT 'hi',
  location VARCHAR(100),
  farm_size DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Crops table for crop management
CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  crop_name VARCHAR(50) NOT NULL,
  variety VARCHAR(50),
  area DECIMAL(10,2),
  planting_date DATE,
  expected_harvest DATE,
  actual_harvest DATE,
  status VARCHAR(20) DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Expenses table for financial tracking
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  date DATE DEFAULT CURRENT_DATE,
  voice_recorded BOOLEAN DEFAULT false,
  voice_file_path VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Categories for expenses
CREATE TABLE expense_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  name_hindi VARCHAR(50),
  color VARCHAR(7) DEFAULT '#007bff'
);

-- Weather data (optional for future use)
CREATE TABLE weather_logs (
  id SERIAL PRIMARY KEY,
  location VARCHAR(100),
  temperature DECIMAL(5,2),
  humidity DECIMAL(5,2),
  rainfall DECIMAL(8,2),
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Market prices (optional for future use)
CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  crop_name VARCHAR(50),
  price_per_kg DECIMAL(10,2),
  market_location VARCHAR(100),
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default expense categories
INSERT INTO expense_categories (name, name_hindi, color) VALUES
('Seeds', 'बीज', '#28a745'),
('Fertilizer', 'उर्वरक', '#17a2b8'),
('Pesticide', 'कीटनाशक', '#ffc107'),
('Labor', 'श्रम', '#dc3545'),
('Fuel', 'ईंधन', '#6f42c1'),
('Equipment', 'उपकरण', '#fd7e14'),
('Irrigation', 'सिंचाई', '#20c997'),
('Transportation', 'परिवहन', '#e83e8c'),
('Other', 'अन्य', '#6c757d');

-- Create indexes for better performance
CREATE INDEX idx_crops_user_id ON crops(user_id);
CREATE INDEX idx_crops_status ON crops(status);
CREATE INDEX idx_crops_planting_date ON crops(planting_date);
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_category ON expenses(category);

-- Functions and triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crops_updated_at 
    BEFORE UPDATE ON crops
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create some sample data for testing (optional)
-- Uncomment these lines if you want test data

/*
INSERT INTO users (phone, name, language, location, farm_size) VALUES
('9876543210', 'राम कुमार', 'hi', 'मेरठ, उत्तर प्रदेश', 5.5),
('9876543211', 'Shyam Singh', 'hi', 'जयपुर, राजस्थान', 3.2),
('9876543212', 'Gita Devi', 'hi', 'लुधियाना, पंजाब', 8.0);

INSERT INTO crops (user_id, crop_name, variety, area, planting_date, expected_harvest) VALUES
(1, 'गेहूं', 'HD-2967', 2.5, '2024-11-15', '2025-04-15'),
(1, 'मक्का', 'NK-30', 3.0, '2024-06-10', '2024-10-10'),
(2, 'बाजरा', 'HHB-67', 1.5, '2024-07-01', '2024-11-01');

INSERT INTO expenses (user_id, category, amount, description) VALUES
(1, 'Seeds', 5000.00, 'गेहूं के बीज खरीदे'),
(1, 'Fertilizer', 3200.00, 'यूरिया खाद'),
(2, 'Labor', 2500.00, 'खेत की जुताई के लिए मजदूर');
*/

-- Views for easier data access
CREATE VIEW user_crop_summary AS
SELECT 
    u.id as user_id,
    u.name,
    COUNT(c.id) as total_crops,
    SUM(c.area) as total_area,
    COUNT(CASE WHEN c.status = 'active' THEN 1 END) as active_crops
FROM users u
LEFT JOIN crops c ON u.id = c.user_id
GROUP BY u.id, u.name;

CREATE VIEW user_expense_summary AS
SELECT 
    u.id as user_id,
    u.name,
    COUNT(e.id) as total_expenses,
    SUM(e.amount) as total_amount,
    AVG(e.amount) as avg_expense
FROM users u
LEFT JOIN expenses e ON u.id = e.user_id
GROUP BY u.id, u.name;

-- Success message
SELECT 'SmartKrishi database schema created successfully!' as status;