import argparse
import geoserver
import geoserver.catalog
import requests

# Add layers to Geoserver
def ConfigureLayersinGeoserver(gs_rest_url, gs_usr, gs_pwd, gs_wkspc_name, gs_ds_name):
    cat = geoserver.catalog.Catalog(geoserverRESTURL, geoserverUser, geoserverPassword)
    ws = cat.get_workspace(geoserverWorkspace)
    if ws is None:
        print 'Creating Workspace'
        ws = cat.create_workspace(geoserverWorkspace, 'http://lcat.usgs.gov/' + geoserverWorkspace)
    else:
        print 'Workspace exists'
    ds = None
    try:
        ds = cat.get_store(geoserverDatastore)
    except Exception, e:
        sys.exc_clear()
        pass
    if ds is None:
        print 'Creating Data Store'
        ds = cat.create_datastore(geoserverDatastore, ws)
        cat.save(ds)
    else:
        print 'Data Store exists'
    layer = cat.create_postgres_layer(geoserverWorkspace, geoserverDatastore, layer, srs='EPSG:4326')
