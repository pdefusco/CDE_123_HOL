
## 6. Promote to higher env using API by replicating repo and redeploy

Now that the job has succeeded, import it into the PRD cluster.

First delete the job and repository in case they have already been created.

```
cde job delete \
  --name cde_spark_job_prd \
  --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1

cde repository delete \
  --name sparkAppRepoPrd \
  --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1
```

Create and sync the same Git repo from the PRD Cluster:

```
cde repository create --name sparkAppRepoPrd \
  --branch main \
  --url https://github.com/pdefusco/CDE_SparkConnect.git \
  --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1

cde repository sync --name sparkAppRepoPrd \
 --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1

cde job create --name cde_spark_job_prd \
  --type spark \
  --mount-1-resource sparkAppRepoPrd \
  --executor-cores 2 \
  --executor-memory "4g" \
  --application-file pyspark-app.py\
  --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1

cde job run --name cde_spark_job_prd \
  --executor-cores 4 \
  --executor-memory "2g" \
  --vcluster-endpoint https://762hjztc.cde-ntvvr5hx.go01-dem.ylcu-atmi.cloudera.site/dex/api/v1
```

## 7. Build Orchestration Pipeline with Airflow

Delete existing jobs in case they have been created.

```
cde job delete \
  --name airflow-orchestration \
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job delete \
  --name cde_spark_job_gold \
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job delete \
  --name cde_spark_job_silver \
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job delete \
  --name cde_spark_job_bronze \
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde repository sync --name sparkAppRepoPrd \
 --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1
```

First create the CDE Spark jobs. Then create the CDE Airflow job.

```
cde job create --name cde_spark_job_bronze \
  --type spark \
  --arg pauldefusco \
  --arg s3a://paul-aug26-buk-a3c2b50a/data/spark3_demo/pdefusco/icedemo \
  --mount-1-resource sparkAppRepoPrd \
  --python-env-resource-name Python-Env-Shared \
  --executor-cores 2 \
  --executor-memory "4g" \
  --application-file code/pyspark_example/airflow_pipeline/001_Lakehouse_Bronze.py\
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job create --name cde_spark_job_silver \
  --type spark \
  --arg pauldefusco \
  --mount-1-resource sparkAppRepoPrd \
  --python-env-resource-name Python-Env-Shared \
  --executor-cores 2 \
  --executor-memory "4g" \
  --application-file code/pyspark_example/airflow_pipeline/002_Lakehouse_Silver.py\
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job create --name cde_spark_job_gold \
  --type spark \
  --arg pauldefusco \
  --arg s3a://paul-aug26-buk-a3c2b50a/spark3_demo/data/pdefusco \
  --mount-1-resource sparkAppRepoPrd \
  --python-env-resource-name Python-Env-Shared \
  --executor-cores 2 \
  --executor-memory "4g" \
  --application-file code/pyspark_example/airflow_pipeline/003_Lakehouse_Gold.py\
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1

cde job create --name airflow-orchestration \
  --type airflow \
  --mount-1-resource sparkAppRepoPrd \
  --dag-file code/pyspark_example/airflow_pipeline/004_airflow_dag_git.py\
  --vcluster-endpoint https://vtr4tm46.cde-vwkzdqwc.paul-aug.a465-9q4k.cloudera.site/dex/api/v1
```
