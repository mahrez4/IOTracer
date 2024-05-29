import numpy as np
import pandas as pd
import plotly.express as px
import wfdb
from dash import Dash, html, dcc
from dash.dependencies import Input, Output


def load_ecg(record_id, segment_id, sampfrom, sampto):

    filename = 'p{:05d}_s{:02d}'.format(record_id, segment_id)
    pn_dir_root = 'icentia11k-continuous-ecg/1.0/'
    pn_dir = 'p{:02d}/p{:05d}/'.format(record_id//1000, record_id)
    
    signals, fileds = wfdb.rdsamp(filename,
                                  pn_dir=pn_dir_root+pn_dir,
                                  sampfrom=sampfrom,
                                  sampto=sampto
                                  )
    
    df_ecg = pd.DataFrame({'sample': np.arange(sampfrom, sampto),
                           'signal': signals[:,0]})
    
    return df_ecg

df_ecg = load_ecg(18, 0, 2*60*250, 3*60*250) # 250 samples per sec
df_ecg.head()