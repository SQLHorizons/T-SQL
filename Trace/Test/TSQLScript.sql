SELECT EmployeeNumber,ShiftDate,TimeSequence,MinuteSequence,FieldSequence,DateRecordChanged,TimeRecordChanged,LastChangedByUser,ShiftTime,
DataField,DataValue,FieldPrefixCode,FieldType,NumericValue,BlockNumber,TimeStamp FROM Equator..FdcValidClockingData WITH (NOLOCK) 
WHERE (EmployeeNumber = '011281  ' AND ShiftDate = '2017-02-14T00:00:00' AND TimeSequence =  2565 AND MinuteSequence =  10 AND FieldSequence >=    0) OR 
(EmployeeNumber = '011281  ' AND ShiftDate = '2017-02-14T00:00:00' AND TimeSequence =  2565 AND MinuteSequence >   10) OR (EmployeeNumber = '011281  ' AND ShiftDate = '2017-02-14T00:00:00' 
AND TimeSequence >   2565) OR (EmployeeNumber = '011281  ' AND ShiftDate >  '2017-02-14T00:00:00') OR (EmployeeNumber >  '011281  ') ORDER BY EmployeeNumber , 
ShiftDate      , TimeSequence      , MinuteSequence      , FieldSequence
