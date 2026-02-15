TellMeWhenDB = {
["global"] = {
["CodeSnippets"] = {
{
["Name"] = "Magic - TBC - Utils",
["Code"] = "[0m[35mPROMETHEUS: [0mApplying Obfuscation Pipeline to /home/ubuntu/MagicSite/storage/app/lua/TBCUtils.generated.lua ...\
[0m[35mPROMETHEUS: [0mParsing ...\
[0m[35mPROMETHEUS: [0mParsing Done in 0.00 seconds\
[0m[35mPROMETHEUS: [0mApplying Step \"Encrypt Strings\" ...\
[0m[35mPROMETHEUS: [0mStep \"Encrypt Strings\" Done in 0.00 seconds\
[0m[35mPROMETHEUS: [0mApplying Step \"Anti Tamper\" ...\
[0m[35mPROMETHEUS: [0mStep \"Anti Tamper\" Done in 0.00 seconds\
[0m[35mPROMETHEUS: [0mApplying Step \"Vmify\" ...\
[0m[35mPROMETHEUS: [0mStep \"Vmify\" Done in 0.00 seconds\
[0m[35mPROMETHEUS: [0mApplying Step \"Constant Array\" ...\
[0m[35mPROMETHEUS: [0mStep \"Constant Array\" Done in 0.00 seconds\
[0m[35mPROMETHEUS: [0mApplying Step \"Numbers To Expressions\" ...\
lua: ...Prometheus/src/prometheus/steps/NumbersToExpressions.lua:48: attempt to perform arithmetic on a nil value\
stack traceback:\
	...Prometheus/src/prometheus/steps/NumbersToExpressions.lua:48: in local 'generator'\
	...Prometheus/src/prometheus/steps/NumbersToExpressions.lua:63: in function 'prometheus.steps.NumbersToExpressions.CreateNumberExpression'\
	(...tail calls...)\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:245: in upvalue 'visitExpression'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:113: in upvalue 'visitStatement'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:72: in upvalue 'visitBlock'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:150: in upvalue 'visitStatement'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:72: in upvalue 'visitBlock'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:150: in upvalue 'visitStatement'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:72: in upvalue 'visitBlock'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:144: in upvalue 'visitStatement'\
	...	(skipping 13 levels)\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:221: in upvalue 'visitExpression'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:208: in upvalue 'visitExpression'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:101: in upvalue 'visitStatement'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:72: in upvalue 'visitBlock'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/visitast.lua:34: in function 'prometheus.visitast'\
	...Prometheus/src/prometheus/steps/NumbersToExpressions.lua:73: in function 'prometheus.steps.NumbersToExpressions.apply'\
	...ackend/luasrcdiet/Prometheus/src/prometheus/pipeline.lua:187: in function 'prometheus.pipeline.apply'\
	/home/ubuntu/auth-backend/luasrcdiet/Prometheus/src/cli.lua:148: in main chunk\
	[C]: in function 'require'\
	/home/ubuntu/auth-backend/luasrcdiet/Prometheus/cli.lua:12: in main chunk\
	[C]: in ?",
}, -- [1]
["n"] = 1,
},
},
}