import ftplib
import os
import pandas as pd
import boto3
from sqlalchemy import create_engine
from io import BytesIO
from dotenv import load_dotenv

load_dotenv()
s3 = boto3.client('s3')
bucket_name = os.getenv('S3_BUCKET')
db_user = os.getenv('DB_USER')
db_password = os.getenv('DB_PASSWORD')
db_host = os.getenv('DB_HOST')
db_port = os.getenv('DB_PORT')
db_name = os.getenv('DB_NAME')
engine = create_engine(f'mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}')

ftp_host = "172.0.0.0"
ftp_user = os.getenv('FTP_USER')
ftp_password = os.getenv('FTP_PASSWORD')
ftp = ftplib.FTP(ftp_host)
ftp.login(ftp_user, ftp_password)

def get_processed_files():
    with engine.connect() as conn:
        result = conn.execute("SELECT filename FROM file_control").fetchall()
    return {row[0] for row in result}

def save_to_database(df, table_name):
    df.to_sql(table_name, con=engine, if_exists='append', index=False)

# Transfere arquivo para o S3
def upload_to_s3(file_name, file_content):
    s3.upload_fileobj(BytesIO(file_content), bucket_name, file_name)

def process_files():
    ftp.cwd('/Relatorios/')  
    processed_files = get_processed_files()
    
    for file_name in ftp.nlst():  
        if file_name.endswith(('.xls', '.xlsx')) and file_name not in processed_files:
            with BytesIO() as file_content:
                ftp.retrbinary(f'RETR {file_name}', file_content.write)
                file_content.seek(0)  

                df = pd.read_excel(file_content)

                save_to_database(df, 'tabela_dados')

                file_content.seek(0) 
                upload_to_s3(file_name, file_content.getvalue())
               
                with engine.connect() as conn:
                    conn.execute("INSERT INTO file_control (filename) VALUES (%s)", (file_name,))

if __name__ == "__main__":
    process_files()

