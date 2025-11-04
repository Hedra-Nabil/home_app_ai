-- =====================================================
-- Supabase Database Setup for Smart Home Voice Assistant
-- =====================================================

-- 1. Create iot_control table
-- This table stores the state of IoT devices (LEDs)
CREATE TABLE IF NOT EXISTS iot_control (
  id TEXT PRIMARY KEY,
  led1 BOOLEAN DEFAULT false,
  led2 BOOLEAN DEFAULT false,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert default device
INSERT INTO iot_control (id, led1, led2)
VALUES ('esp32s3-C54908', false, false)
ON CONFLICT (id) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE iot_control ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (for development)
DROP POLICY IF EXISTS "Allow all operations on iot_control" ON iot_control;
CREATE POLICY "Allow all operations on iot_control"
ON iot_control
FOR ALL
USING (true)
WITH CHECK (true);

-- =====================================================

-- 2. Create voice_commands table
-- This table stores all voice commands history
CREATE TABLE IF NOT EXISTS voice_commands (
  id SERIAL PRIMARY KEY,
  command TEXT NOT NULL,
  action TEXT,
  confidence INTEGER,
  response TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE voice_commands ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (for development)
DROP POLICY IF EXISTS "Allow all operations on voice_commands" ON voice_commands;
CREATE POLICY "Allow all operations on voice_commands"
ON voice_commands
FOR ALL
USING (true)
WITH CHECK (true);

-- =====================================================

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_iot_control_updated 
ON iot_control(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_voice_commands_timestamp 
ON voice_commands(timestamp DESC);

-- =====================================================

-- 4. Verify tables
SELECT 'iot_control table' AS table_name, COUNT(*) AS row_count FROM iot_control
UNION ALL
SELECT 'voice_commands table' AS table_name, COUNT(*) AS row_count FROM voice_commands;

-- =====================================================
-- How to use:
-- 1. Open Supabase Dashboard
-- 2. Go to SQL Editor
-- 3. Copy and paste this entire script
-- 4. Click "Run"
-- 5. Check that tables are created successfully
-- =====================================================
