-- جدول لحفظ معلومات النظام والموقع والطقس
CREATE TABLE IF NOT EXISTS system_info (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- معلومات الوقت والتاريخ
  date TEXT,
  time TEXT,
  day_name TEXT,
  
  -- معلومات الموقع
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  city TEXT,
  country TEXT,
  
  -- معلومات الطقس
  temperature DOUBLE PRECISION,
  humidity DOUBLE PRECISION,
  wind_speed DOUBLE PRECISION,
  weather_description TEXT,
  
  -- فهرس للبحث السريع
  CONSTRAINT system_info_device_id_idx UNIQUE (device_id, timestamp)
);

-- إنشاء فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_system_info_device_timestamp 
ON system_info (device_id, timestamp DESC);

-- تفعيل RLS (Row Level Security)
ALTER TABLE system_info ENABLE ROW LEVEL SECURITY;

-- سياسة للسماح بالقراءة والكتابة للجميع (يمكن تخصيصها حسب الحاجة)
CREATE POLICY "Enable read access for all users" ON system_info
  FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON system_info
  FOR INSERT WITH CHECK (true);
