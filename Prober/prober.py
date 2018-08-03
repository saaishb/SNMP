#!/usr/bin/env python
import sys
import time
from easysnmp import snmp_get
 
cla = sys.argv
tid = 1/float(cla[2])
h,p,c = cla[1].split(':')
cla.insert(4,'1.3.6.1.2.1.1.3.0') #insert sysuptime
	
	

alloids = []
for j in range(4,len(cla)):
	alloids.append(cla[j])

for z in range(1,len(cla)-4):
	globals()['a%s' %z] = 0
	globals()['b%s' %z] = 0

for i in range(0,int(cla[3])+1):
	x1 = time.time()	
	if i!=0:
		print int(time.time()),'|',          #print time for every sample

	get_list = snmp_get(alloids, hostname=h,remote_port = p, community=c,version=2,timeout=1,retries=1) #storing all requests in list
	for y in range(0,len(get_list)):
		if get_list[y].value=="NOSUCHINSTANCE" or get_list[y].value=="NOSUCHOBJECT":
			get_list.remove(get_list[y]) # remove if there is wrong oid
	
	for x in range(1,len(get_list)): #caluculate rate 
		globals()['c%s' %x] = get_list[x].value
		globals()['d%s' %x] = get_list[x].snmp_type
		globals()['t%s' %x]= time.time()
		if i!=0:
			diff = ((int(globals()['c%s' %x])-globals()['a%s' %x]))
			tdiff = round(globals()['t%s' %x]-globals()['b%s' %x],1)

			if diff<0: #check for counter type
				if str(globals()['d%s' %x])=='COUNTER':
					diff = diff + 2**32	
					print int(diff/tdiff),'|',
					if x==len(get_list)-1:
						print ""
				elif str(globals()['d%s' %x])=='COUNTER64':
					diff = diff + 2**64	
					print int(diff/tdiff),'|',
					if x==len(get_list)-1:
						print ""
			elif diff>=0:
				print int(diff/tdiff),'|',
				if x==len(get_list)-1:
					print ""
		
		globals()['a%s' %x] = int(globals()['c%s' %x])
		globals()['b%s' %x] = globals()['t%s' %x]
	x2 =time.time()
	time.sleep(abs(tid-x2+x1))
