from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional

class Transaction(BaseModel):
    sku: str = Field(..., description="Mã sản phẩm")
    type: str = Field(..., description="Loại giao dịch: 'inbound' hoặc 'outbound'")
    qty: int = Field(..., gt=0, description="Số lượng sản phẩm")
    wh: str = Field(..., description="Mã kho")
    by: str = Field(..., description="Người thực hiện giao dịch")
    note: Optional[str] = Field("", description="Ghi chú (nếu có)")
    at: datetime = Field(default_factory=datetime.utcnow, description="Thời gian giao dịch")

    class Config:
        schema_extra = {
            "example": {
                "sku": "SKU12345",
                "type": "inbound",
                "qty": 50,
                "wh": "WH01",
                "by": "admin",
                "note": "Nhập bổ sung",
                "at": "2025-08-24T08:30:00Z"
            }
        }
