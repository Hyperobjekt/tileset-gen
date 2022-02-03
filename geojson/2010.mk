# Creates GeoJSON files from Census shapefiles for 2010

census_ftp_base = ftp://ftp2.census.gov/geo/tiger/GENZ2010/

block-groups-pattern = gz_*_*_150_*_500k.zip
tracts-pattern = gz_*_*_140_*_500k.zip
cities-pattern = gz_*_*_160_*_500k.zip
counties-pattern = gz_*_*_050_*_500k.zip
states-pattern = gz_*_*_040_*_500k.zip
zips-pattern = gz_*_*_860_*_500k.zip

block-groups-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY + this.properties.TRACT + this.properties.BLKGRP"
tracts-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY + this.properties.TRACT"
cities-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.PLACE"
counties-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY"
states-geoid =  "this.properties.GEOID = this.properties.STATE"
zips-geoid = "this.properties.GEOID = this.properties.ZCTA5"

geo_types = states counties cities tracts block-groups zips
GENERATED_FILES = $(foreach t, $(geo_types), 2010/$(t).geojson)
GZIP_FILES = $(foreach t, $(geo_types), 2010/$(t).geojson.gz)

.PHONY: all states counties cities tracts block-groups help

## all                 : Create all census GeoJSON
all: $(GENERATED_FILES)

all_gzip: $(GZIP_FILES)

states: 2010/states.geojson

counties: 2010/counties.geojson

cities: 2010/cities.geojson

tracts: 2010/tracts.geojson

block-groups: 2010/block-groups.geojson

zips: 2010/zips.geojson

## help                : Print help
help: Makefile
	perl -ne '/^## / && s/^## //g && print' $<

2010/%.geojson.gz: 2010/%.geojson
	gzip -c $< > $@

.SECONDARY:
deploy:
	for f in ./2010/*.geojson; do aws s3 cp $$f s3://hyperobjekt-geojson/2010/; done

.SECONDARY:
deploygz: 
	for f in ./2010/*.geojson.gz; do aws s3 cp $$f s3://hyperobjekt-geojson/2010/; done

## 2010/%.geojson    : Download and clean census GeoJSON
.SECONDARY:
2010/%.geojson:
	mkdir -p 2010/$*
	wget --no-use-server-timestamps -np -nd -r -P 2010/$* -A '$($*-pattern)' $(census_ftp_base)
	for f in ./2010/$*/*.zip; do unzip -d ./2010/$* $$f; done
	mapshaper ./2010/$*/*.shp combine-files \
		-each $($*-geoid) \
		-o $@ combine-layers format=geojson

