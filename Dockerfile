FROM python:2.7.15-stretch

EXPOSE 8889

RUN pip install --upgrade ipykernel==4.3.1
RUN pip install --upgrade ipython==4.2.0
RUN pip install --upgrade ipython-genutils==0.1.0
RUN pip install --upgrade jupyter==1.0.0
RUN pip install --upgrade jupyter-console==4.1.1
RUN pip install --upgrade jupyter-core==4.1.0
RUN pip install --upgrade matplotlib==2.0.2
RUN pip install --upgrade numpy==1.14.2
RUN pip install --upgrade jupyter-client
RUN pip install --upgrade notebook
RUN pip install --upgrade ipywidgets==4.1.1

CMD ["sh", "-c", "jupyter notebook --port=8889 --no-browser --ip=* --allow-root"]