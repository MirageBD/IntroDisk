(define memories
'(
	(memory zeroPage (address (#x2 . #x7f)) (type ram) (qualifier zpage)
		(section (registers #x2))
	)
	
	(memory stackPage (address (#x100 . #x1ff))
		(type ram)
	)

	(memory prog (address (#x1600 . #x7fff)) (type any)
		(section
			(programStart #x1600)
			startup
			code
			data
			switch
			cdata
			data_init_table
		)
	)
))
