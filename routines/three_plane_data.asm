SUCount: db 0
SUStatic: db 0
SUNoRoom: db 0
SUDropped: db 0
SUWindowValid: db 0
SUDataNext: dw SUData
SURecords: ds 66,0       ; eleven compact records: E-bottom, cols, rows, data
SURecordNext: dw SURecords
SUWorkDst: dw 0
SUWorkCols: db 0
SUWorkRows: db 0
SUWorkData: dw 0
SUPlane: db 0
SUPlaneDst: dw 0
SURestoreLeft: db 0
SURestoreRecord: dw 0
SUCopySP: dw 0
